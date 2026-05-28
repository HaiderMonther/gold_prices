import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource, Between, MoreThanOrEqual, LessThanOrEqual } from 'typeorm';
import { Invoice, InvoiceType } from '../invoices/invoice.entity';
import { Expense } from '../expenses/expense.entity';
import { Purchase } from '../purchases/purchase.entity';
import { Product, ProductStatus } from '../products/product.entity';
import { Debt } from '../debts/debt.entity';
import { InvoiceItem } from '../invoices/invoice-item.entity';
import { Customer } from '../customers/customer.entity';
import { Transfer } from '../transfers/transfer.entity';

@Injectable()
export class ReportsService {
  constructor(
    @InjectRepository(Invoice) private invoiceRepo: Repository<Invoice>,
    @InjectRepository(Expense) private expenseRepo: Repository<Expense>,
    @InjectRepository(Purchase) private purchaseRepo: Repository<Purchase>,
    @InjectRepository(Product) private productRepo: Repository<Product>,
    @InjectRepository(Debt) private debtRepo: Repository<Debt>,
    @InjectRepository(InvoiceItem) private itemRepo: Repository<InvoiceItem>,
    @InjectRepository(Customer) private customerRepo: Repository<Customer>,
    @InjectRepository(Transfer) private transferRepo: Repository<Transfer>,
    private dataSource: DataSource,
  ) {}

  async getDashboardStats(tenantId?: string) {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const salesQuery = this.invoiceRepo
      .createQueryBuilder('i')
      .select('SUM(i.total_amount)', 'total')
      .addSelect('COUNT(i.id)', 'count')
      .where("i.type = 'sale'");
    if (tenantId) salesQuery.andWhere('i.tenant_id = :tenantId', { tenantId });
    const [totalSales] = await salesQuery.getRawMany();

    const todaySalesQuery = this.invoiceRepo
      .createQueryBuilder('i')
      .select('SUM(i.total_amount)', 'total')
      .addSelect('COUNT(i.id)', 'count')
      .where("i.type = 'sale'")
      .andWhere('i.created_at >= :today', { today });
    if (tenantId) todaySalesQuery.andWhere('i.tenant_id = :tenantId', { tenantId });
    const [todaySales] = await todaySalesQuery.getRawMany();

    const expensesQuery = this.expenseRepo.createQueryBuilder('e').select('SUM(e.amount)', 'total');
    if (tenantId) expensesQuery.where('e.tenant_id = :tenantId', { tenantId });
    const [totalExpenses] = await expensesQuery.getRawMany();

    // Real Profit Calculation: Sum of craftsmanship (craft_price) from all sales
    const profitQuery = this.itemRepo
      .createQueryBuilder('item')
      .innerJoin('item.invoice', 'i')
      .select('SUM(item.craft_price)', 'totalProfit')
      .where("i.type = 'sale'");
    if (tenantId) profitQuery.andWhere('i.tenant_id = :tenantId', { tenantId });
    const [profitData] = await profitQuery.getRawMany();

    const inventoryQuery = this.productRepo
      .createQueryBuilder('p')
      .select('p.status', 'status')
      .addSelect('COUNT(p.id)', 'count')
      .addSelect('SUM(p.weight)', 'total_weight')
      .groupBy('p.status');
    if (tenantId) inventoryQuery.where('p.tenant_id = :tenantId', { tenantId });
    const inventoryStats = await inventoryQuery.getRawMany();

    const debtsQuery = this.debtRepo
      .createQueryBuilder('d')
      .select('SUM(d.amount - d.paid_amount)', 'total')
      .addSelect('COUNT(d.id)', 'count')
      .where('d.is_paid = false');
    if (tenantId) debtsQuery.andWhere('d.tenant_id = :tenantId', { tenantId });
    const [unpaidDebts] = await debtsQuery.getRawMany();

    // Today's purchases
    const purchasesQuery = this.purchaseRepo
      .createQueryBuilder('p')
      .select('SUM(p.paid_amount)', 'total')
      .addSelect('COUNT(p.id)', 'count')
      .addSelect('SUM(p.weight)', 'weight')
      .where('p.created_at >= :today', { today });
    if (tenantId) purchasesQuery.andWhere('p.tenant_id = :tenantId', { tenantId });
    const [todayPurchases] = await purchasesQuery.getRawMany();

    return {
      sales: { 
        total: parseFloat(totalSales?.total || '0'), 
        count: parseInt(totalSales?.count || '0') 
      },
      today: {
        total: parseFloat(todaySales?.total || '0'),
        count: parseInt(todaySales?.count || '0')
      },
      todayPurchases: {
        total: parseFloat(todayPurchases?.total || '0'),
        count: parseInt(todayPurchases?.count || '0'),
        weight: parseFloat(todayPurchases?.weight || '0'),
      },
      profit: {
        total: parseFloat(profitData?.totalProfit || '0')
      },
      expenses: { total: parseFloat(totalExpenses?.total || '0') },
      inventory: inventoryStats,
      debts: {
        total: parseFloat(unpaidDebts?.total || '0'),
        count: parseInt(unpaidDebts?.count || '0'),
      },
    };
  }

  // ==================== كشف الحساب المفصل ====================
  async getAccountStatement(customerId: string, dateFrom?: string, dateTo?: string) {
    const customer = await this.customerRepo.findOne({ where: { id: customerId } });
    if (!customer) throw new Error('العميل غير موجود');

    const dateFilter: any = {};
    if (dateFrom && dateTo) {
      dateFilter.created_at = Between(new Date(dateFrom), new Date(dateTo + 'T23:59:59'));
    } else if (dateFrom) {
      dateFilter.created_at = MoreThanOrEqual(new Date(dateFrom));
    } else if (dateTo) {
      dateFilter.created_at = LessThanOrEqual(new Date(dateTo + 'T23:59:59'));
    }

    // Invoices (sales to this customer)
    const invoices = await this.invoiceRepo.find({
      where: { customer_id: customerId, ...dateFilter },
      relations: ['items', 'items.product'],
      order: { created_at: 'ASC' },
    });

    // Debts and payments
    const debts = await this.debtRepo.find({
      where: { customer_id: customerId, ...dateFilter },
      order: { created_at: 'ASC' },
    });

    // Transfers involving this customer
    const transfersFrom = await this.transferRepo.find({
      where: { from_customer_id: customerId, ...dateFilter },
      relations: ['to_customer'],
      order: { created_at: 'ASC' },
    });
    const transfersTo = await this.transferRepo.find({
      where: { to_customer_id: customerId, ...dateFilter },
      relations: ['from_customer'],
      order: { created_at: 'ASC' },
    });

    // Build unified timeline
    const entries = [];

    for (const inv of invoices) {
      const totalWeight = inv.items?.reduce((s, i) => s + parseFloat(String(i.weight)), 0) || 0;
      entries.push({
        date: inv.created_at,
        type: inv.type === 'sale' ? 'sale' : 'return',
        description: inv.type === 'sale' 
          ? `فاتورة بيع #${inv.invoice_number}` 
          : `إرجاع #${inv.invoice_number}`,
        debit: inv.type === 'sale' ? parseFloat(String(inv.total_amount)) : 0,
        credit: inv.type === 'return' ? parseFloat(String(inv.total_amount)) : 0,
        paid: parseFloat(String(inv.paid_amount)),
        weight: totalWeight,
        reference_id: inv.id,
        invoice_number: inv.invoice_number,
      });
    }

    for (const d of debts) {
      if (parseFloat(String(d.paid_amount)) > 0) {
        entries.push({
          date: d.created_at,
          type: 'payment',
          description: `سداد دين${d.invoice_id ? ' (فاتورة)' : ''}`,
          debit: 0,
          credit: parseFloat(String(d.paid_amount)),
          paid: parseFloat(String(d.paid_amount)),
          weight: 0,
          reference_id: d.id,
        });
      }
    }

    for (const t of transfersFrom) {
      entries.push({
        date: t.created_at,
        type: 'transfer_out',
        description: `حوالة صادرة إلى ${t.to_customer?.name || 'غير محدد'}`,
        debit: parseFloat(String(t.amount)),
        credit: 0,
        paid: 0,
        weight: 0,
        reference_id: t.id,
      });
    }

    for (const t of transfersTo) {
      entries.push({
        date: t.created_at,
        type: 'transfer_in',
        description: `حوالة واردة من ${t.from_customer?.name || 'غير محدد'}`,
        debit: 0,
        credit: parseFloat(String(t.amount)),
        paid: 0,
        weight: 0,
        reference_id: t.id,
      });
    }

    // Sort by date
    entries.sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());

    // Calculate running balance
    let balance = 0;
    for (const entry of entries) {
      balance += entry.debit - entry.credit;
      entry.balance = balance;
    }

    const totalDebit = entries.reduce((s, e) => s + e.debit, 0);
    const totalCredit = entries.reduce((s, e) => s + e.credit, 0);
    const totalWeight = entries.reduce((s, e) => s + e.weight, 0);

    return {
      customer,
      entries,
      summary: {
        totalDebit,
        totalCredit,
        netBalance: totalDebit - totalCredit,
        totalWeight,
      },
    };
  }

  // ==================== تقرير التداول اليومي ====================
  async getDailyTrading(tenantId?: string, date?: string) {
    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    const salesWhere: any = { type: InvoiceType.SALE, created_at: Between(startOfDay, endOfDay) };
    if (tenantId) salesWhere.tenant_id = tenantId;
    const sales = await this.invoiceRepo.find({
      where: salesWhere,
      relations: ['items', 'customer'],
      order: { created_at: 'ASC' },
    });

    const purchasesWhere: any = { created_at: Between(startOfDay, endOfDay) };
    if (tenantId) purchasesWhere.tenant_id = tenantId;
    const purchases = await this.purchaseRepo.find({
      where: purchasesWhere,
      order: { created_at: 'ASC' },
    });

    const expensesWhere: any = { created_at: Between(startOfDay, endOfDay) };
    if (tenantId) expensesWhere.tenant_id = tenantId;
    const expenses = await this.expenseRepo.find({
      where: expensesWhere,
      order: { created_at: 'ASC' },
    });

    const totalSalesAmount = sales.reduce((s, i) => s + parseFloat(String(i.total_amount)), 0);
    const totalSalesWeight = sales.reduce((s, i) => 
      s + (i.items?.reduce((w, it) => w + parseFloat(String(it.weight)), 0) || 0), 0);
    const totalPurchasesAmount = purchases.reduce((s, p) => s + parseFloat(String(p.paid_amount)), 0);
    const totalPurchasesWeight = purchases.reduce((s, p) => s + parseFloat(String(p.weight)), 0);
    const totalExpenses = expenses.reduce((s, e) => s + parseFloat(String(e.amount)), 0);

    return {
      date: startOfDay.toISOString().split('T')[0],
      sales: { items: sales, total: totalSalesAmount, weight: totalSalesWeight, count: sales.length },
      purchases: { items: purchases, total: totalPurchasesAmount, weight: totalPurchasesWeight, count: purchases.length },
      expenses: { items: expenses, total: totalExpenses, count: expenses.length },
      netCash: totalSalesAmount - totalPurchasesAmount - totalExpenses,
    };
  }

  // ==================== ملخص الموجود حسب العيار ====================
  async getInventorySummary(tenantId?: string) {
    const byKaratQuery = this.productRepo
      .createQueryBuilder('p')
      .select('p.karat', 'karat')
      .addSelect('COUNT(p.id)', 'count')
      .addSelect('SUM(p.weight)', 'total_weight')
      .addSelect('SUM(p.craft_price)', 'total_craft')
      .where('p.status = :status', { status: ProductStatus.AVAILABLE })
      .groupBy('p.karat')
      .orderBy('p.karat', 'DESC');
    if (tenantId) byKaratQuery.andWhere('p.tenant_id = :tenantId', { tenantId });
    const byKarat = await byKaratQuery.getRawMany();

    const totalsQuery = this.productRepo
      .createQueryBuilder('p')
      .select('COUNT(p.id)', 'count')
      .addSelect('SUM(p.weight)', 'total_weight')
      .where('p.status = :status', { status: ProductStatus.AVAILABLE });
    if (tenantId) totalsQuery.andWhere('p.tenant_id = :tenantId', { tenantId });
    const totals = await totalsQuery.getRawOne();

    return { byKarat, totals };
  }

  // ==================== موازنة البيع والشراء ====================
  async getSalesVsPurchases(tenantId?: string, dateFrom?: string, dateTo?: string) {
    const salesQuery = this.invoiceRepo.createQueryBuilder('i')
      .innerJoin('i.items', 'item')
      .select('SUM(i.total_amount)', 'totalAmount')
      .addSelect('SUM(item.weight)', 'totalWeight')
      .addSelect('SUM(item.craft_price)', 'totalCraft')
      .addSelect('COUNT(DISTINCT i.id)', 'count')
      .where("i.type = 'sale'");
    if (tenantId) salesQuery.andWhere('i.tenant_id = :tenantId', { tenantId });

    const purchasesQuery = this.purchaseRepo.createQueryBuilder('p')
      .select('SUM(p.paid_amount)', 'totalAmount')
      .addSelect('SUM(p.weight)', 'totalWeight')
      .addSelect('COUNT(p.id)', 'count');
    if (tenantId) purchasesQuery.where('p.tenant_id = :tenantId', { tenantId });

    if (dateFrom) {
      salesQuery.andWhere('i.created_at >= :from', { from: new Date(dateFrom) });
      purchasesQuery.andWhere('p.created_at >= :from', { from: new Date(dateFrom) });
    }
    if (dateTo) {
      salesQuery.andWhere('i.created_at <= :to', { to: new Date(dateTo + 'T23:59:59') });
      purchasesQuery.andWhere('p.created_at <= :to', { to: new Date(dateTo + 'T23:59:59') });
    }

    const [sales] = await salesQuery.getRawMany();
    const [purchases] = await purchasesQuery.getRawMany();

    return {
      sales: {
        totalAmount: parseFloat(sales?.totalAmount || '0'),
        totalWeight: parseFloat(sales?.totalWeight || '0'),
        totalCraft: parseFloat(sales?.totalCraft || '0'),
        count: parseInt(sales?.count || '0'),
      },
      purchases: {
        totalAmount: parseFloat(purchases?.totalAmount || '0'),
        totalWeight: parseFloat(purchases?.totalWeight || '0'),
        count: parseInt(purchases?.count || '0'),
      },
    };
  }

  // ==================== تقرير الأرباح ====================
  async getProfitReport(tenantId?: string, dateFrom?: string, dateTo?: string) {
    const query = this.itemRepo
      .createQueryBuilder('item')
      .innerJoin('item.invoice', 'i')
      .select('SUM(item.craft_price)', 'totalCraft')
      .addSelect('SUM(item.weight * item.price_per_gram)', 'totalGoldValue')
      .addSelect('SUM(item.total_price)', 'totalSales')
      .addSelect('COUNT(DISTINCT i.id)', 'invoiceCount')
      .where("i.type = 'sale'");
    if (tenantId) query.andWhere('i.tenant_id = :tenantId', { tenantId });

    if (dateFrom) query.andWhere('i.created_at >= :from', { from: new Date(dateFrom) });
    if (dateTo) query.andWhere('i.created_at <= :to', { to: new Date(dateTo + 'T23:59:59') });

    const [result] = await query.getRawMany();

    const expensesQuery = this.expenseRepo
      .createQueryBuilder('e')
      .select('SUM(e.amount)', 'total');
    if (tenantId) expensesQuery.where('e.tenant_id = :tenantId', { tenantId });
    const [expensesResult] = await expensesQuery.getRawMany();

    return {
      craftProfit: parseFloat(result?.totalCraft || '0'),
      goldValue: parseFloat(result?.totalGoldValue || '0'),
      totalSales: parseFloat(result?.totalSales || '0'),
      invoiceCount: parseInt(result?.invoiceCount || '0'),
      totalExpenses: parseFloat(expensesResult?.total || '0'),
      netProfit: parseFloat(result?.totalCraft || '0') - parseFloat(expensesResult?.total || '0'),
    };
  }

  // ==================== تقرير الديون ====================
  async getDebtReport(tenantId?: string) {
    const where: any = { is_paid: false };
    if (tenantId) where.tenant_id = tenantId;
    const debts = await this.debtRepo.find({
      where,
      relations: ['customer', 'invoice'],
      order: { created_at: 'DESC' },
    });

    // Group by customer
    const byCustomer: Record<string, { customer: any; totalDebt: number; totalPaid: number; remaining: number; debts: any[] }> = {};
    for (const d of debts) {
      const cId = d.customer_id;
      if (!byCustomer[cId]) {
        byCustomer[cId] = {
          customer: d.customer,
          totalDebt: 0,
          totalPaid: 0,
          remaining: 0,
          debts: [],
        };
      }
      byCustomer[cId].totalDebt += parseFloat(String(d.amount));
      byCustomer[cId].totalPaid += parseFloat(String(d.paid_amount));
      byCustomer[cId].remaining += parseFloat(String(d.amount)) - parseFloat(String(d.paid_amount));
      byCustomer[cId].debts.push(d);
    }

    const groups = Object.values(byCustomer).sort((a, b) => b.remaining - a.remaining);
    const totalRemaining = groups.reduce((s, g) => s + g.remaining, 0);

    return { groups, totalRemaining, totalCount: debts.length };
  }

  async resetSystem(tenantId?: string) {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();
    try {
      if (tenantId) {
        // Delete only this tenant's data
        await queryRunner.query(`DELETE FROM "invoice_items" WHERE invoice_id IN (SELECT id FROM "invoices" WHERE tenant_id = $1)`, [tenantId]);
        await queryRunner.query(`DELETE FROM "debts" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "invoices" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "expenses" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "purchases" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "products" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "customers" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "inventory_checks" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "gold_prices" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "cash_box" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "transfers" WHERE tenant_id = $1`, [tenantId]);
        await queryRunner.query(`DELETE FROM "notifications" WHERE tenant_id = $1`, [tenantId]);
      } else {
        // Super admin: truncate all
        await queryRunner.query('TRUNCATE TABLE "invoice_items" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "debts" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "invoices" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "expenses" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "purchases" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "products" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "customers" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "inventory_checks" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "gold_prices" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "cash_box" CASCADE');
        await queryRunner.query('TRUNCATE TABLE "transfers" CASCADE');
      }
      await queryRunner.commitTransaction();
      return { message: 'تم حذف جميع البيانات بنجاح، النظام الآن جاهز للعمل' };
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async getMonthlySales(tenantId?: string) {
    const query = this.invoiceRepo
      .createQueryBuilder('i')
      .select("DATE_TRUNC('month', i.created_at)", 'month')
      .addSelect('SUM(i.total_amount)', 'total')
      .addSelect('COUNT(i.id)', 'count')
      .where("i.type = 'sale'")
      .groupBy("DATE_TRUNC('month', i.created_at)")
      .orderBy('month', 'DESC')
      .limit(12);
    if (tenantId) query.andWhere('i.tenant_id = :tenantId', { tenantId });
    return query.getRawMany();
  }

  private buildDateFilter(dateFrom?: string, dateTo?: string) {
    const filter: any = {};
    if (dateFrom && dateTo) {
      filter.created_at = Between(new Date(dateFrom), new Date(dateTo + 'T23:59:59'));
    } else if (dateFrom) {
      filter.created_at = MoreThanOrEqual(new Date(dateFrom));
    } else if (dateTo) {
      filter.created_at = LessThanOrEqual(new Date(dateTo + 'T23:59:59'));
    }
    return filter;
  }
}
