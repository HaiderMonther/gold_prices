import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Invoice, InvoiceType, InvoiceStatus } from './invoice.entity';
import { InvoiceItem } from './invoice-item.entity';
import { Product, ProductStatus } from '../products/product.entity';
import { Customer } from '../customers/customer.entity';
import { Debt } from '../debts/debt.entity';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class InvoicesService {
  constructor(
    @InjectRepository(Invoice) private repo: Repository<Invoice>,
    @InjectRepository(InvoiceItem) private itemRepo: Repository<InvoiceItem>,
    @InjectRepository(Product) private productRepo: Repository<Product>,
    @InjectRepository(Customer) private customerRepo: Repository<Customer>,
    @InjectRepository(Debt) private debtRepo: Repository<Debt>,
    private dataSource: DataSource,
    private notificationsService: NotificationsService,
  ) {}

  async findAll(tenantId?: string) {
    try {
      const where: any = {};
      if (tenantId) where.tenant_id = tenantId;
      return await this.repo.find({
        where,
        order: { created_at: 'DESC' },
        relations: ['customer', 'user', 'items', 'items.product'],
      });
    } catch (error) {
      throw new Error(`Database error in findAll: ${error.message}`);
    }
  }

  async findOne(id: string) {
    const inv = await this.repo.findOne({
      where: { id },
      relations: ['customer', 'user', 'items', 'items.product', 'debt'],
    });
    if (!inv) throw new NotFoundException('الفاتورة غير موجودة');
    return inv;
  }

  async create(dto: {
    type?: InvoiceType;
    status?: InvoiceStatus;
    customer_id?: string;
    paid_amount: number;
    discount?: number;
    notes?: string;
    user_id?: string;
    tenant_id?: string;
    items: Array<{
      product_id?: string;
      item_name?: string;
      weight: number;
      karat: number;
      price_per_gram: number;
      craft_price?: number;
    }>;
  }) {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      const invoiceNumber = `INV-${Date.now()}`;
      let totalAmount = 0;

      const invoiceItems: InvoiceItem[] = [];
      for (const item of dto.items) {
        const totalPrice = item.weight * item.price_per_gram + (item.craft_price || 0);
        totalAmount += totalPrice;

        const invoiceItem = this.itemRepo.create({
          product_id: item.product_id || null,
          item_name: item.item_name || (item.product_id ? undefined : 'قطعة حرة'),
          weight: item.weight,
          karat: item.karat,
          price_per_gram: item.price_per_gram,
          craft_price: item.craft_price || 0,
          total_price: totalPrice,
        });
        invoiceItems.push(invoiceItem);

        // Update product status only if it's not a draft
        if (dto.status !== InvoiceStatus.DRAFT) {
          if (dto.type === InvoiceType.PURCHASE) {
             // For purchase, we create the product
           const newProduct = this.productRepo.create({
               name: item.item_name || 'قطعة من مشتريات',
               weight: item.weight,
               karat: item.karat,
               craft_price: item.craft_price || 0,
               status: ProductStatus.AVAILABLE,
               tenant_id: dto.tenant_id || null,
             });
             const savedProduct = await queryRunner.manager.save(Product, newProduct);
             invoiceItem.product_id = savedProduct.id;
          } else if (item.product_id) {
             if (dto.type !== InvoiceType.RETURN) {
               await queryRunner.manager.update(Product, item.product_id, { status: ProductStatus.SOLD });
             } else {
               await queryRunner.manager.update(Product, item.product_id, { status: ProductStatus.AVAILABLE });
             }
          }
        }
      }

      totalAmount -= (dto.discount || 0);
      const remaining = totalAmount - (dto.paid_amount || 0);

      const invoice = this.repo.create({
        invoice_number: invoiceNumber,
        type: dto.type || InvoiceType.SALE,
        status: dto.status || InvoiceStatus.COMPLETED,
        customer_id: dto.customer_id,
        user_id: dto.user_id,
        total_amount: totalAmount,
        paid_amount: dto.paid_amount || 0,
        discount: dto.discount || 0,
        remaining,
        notes: dto.notes,
        items: invoiceItems,
      });

      const savedInvoice = await queryRunner.manager.save(Invoice, invoice);

      // Create debt if there's a remaining amount
      if (remaining > 0 && dto.customer_id && dto.status !== InvoiceStatus.DRAFT) {
        const isPurchase = dto.type === InvoiceType.PURCHASE;
        const debtAmount = isPurchase ? -remaining : remaining; // negative means we owe them
        
        const debt = this.debtRepo.create({
          customer_id: dto.customer_id,
          amount: debtAmount,
          paid_amount: 0,
          is_paid: false,
          invoice_id: savedInvoice.id,
          notes: isPurchase ? `مستحقات للتجار من فاتورة شراء ${invoiceNumber}` : `دين من فاتورة بيع ${invoiceNumber}`,
        });
        await queryRunner.manager.save(Debt, debt);

        // Update customer debt balance
        await queryRunner.manager.increment(Customer, { id: dto.customer_id }, 'debt_balance', debtAmount);
      }

      await queryRunner.commitTransaction();
      
      // Create notification for new invoice
      if (dto.status !== InvoiceStatus.DRAFT) {
        try {
          const title = dto.type === InvoiceType.PURCHASE ? 'فاتورة شراء جديدة' : 'فاتورة بيع جديدة';
          const message = `تم إصدار ${title} برقم #${invoiceNumber}`;
          await this.notificationsService.create({
            title,
            message,
            type: 'success',
            icon: 'receipt',
            tenant_id: dto.tenant_id,
          });
        } catch (notifErr) {
          console.error('Failed to create notification:', notifErr);
        }
      }

      return this.findOne(savedInvoice.id);
    } catch (error) {
      await queryRunner.rollbackTransaction();
      throw error;
    } finally {
      await queryRunner.release();
    }
  }

  async remove(id: string) {
    const inv = await this.findOne(id);
    await this.repo.remove(inv);
    return { message: 'تم حذف الفاتورة' };
  }
}
