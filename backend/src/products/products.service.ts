import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product, ProductStatus } from './product.entity';

@Injectable()
export class ProductsService {
  constructor(@InjectRepository(Product) private repo: Repository<Product>) {}

  findAll(status?: ProductStatus, tenantId?: string) {
    const where: any = {};
    if (status) where.status = status;
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({ where, order: { created_at: 'DESC' }, relations: ['created_by_user'] });
  }

  async findOne(id: string) {
    const p = await this.repo.findOne({ where: { id }, relations: ['created_by_user'] });
    if (!p) throw new NotFoundException('المنتج غير موجود');
    return p;
  }

  async findByBarcode(barcode: string) {
    const p = await this.repo.findOne({ where: { barcode } });
    if (!p) throw new NotFoundException('الباركود غير موجود');
    return p;
  }

  create(dto: any, userId?: string, tenantId?: string) {
    return this.repo.save(this.repo.create({ ...dto, created_by: userId, tenant_id: tenantId || null }));
  }

  async update(id: string, dto: Partial<Product>) {
    await this.findOne(id);
    await this.repo.update(id, dto);
    return this.repo.findOne({ where: { id } });
  }

  async remove(id: string) {
    const p = await this.findOne(id);
    await this.repo.remove(p);
    return { message: 'تم حذف المنتج' };
  }

  async getInventoryStats(tenantId?: string) {
    const query = this.repo
      .createQueryBuilder('p')
      .select('p.status', 'status')
      .addSelect('COUNT(p.id)', 'count')
      .addSelect('SUM(p.weight)', 'total_weight')
      .groupBy('p.status');
    if (tenantId) query.where('p.tenant_id = :tenantId', { tenantId });
    return query.getRawMany();
  }
}
