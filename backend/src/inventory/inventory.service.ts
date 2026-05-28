import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { InventoryCheck } from './inventory-check.entity';
import { Product, ProductStatus } from '../products/product.entity';

@Injectable()
export class InventoryService {
  constructor(
    @InjectRepository(InventoryCheck) private repo: Repository<InventoryCheck>,
    @InjectRepository(Product) private productRepo: Repository<Product>,
  ) {}

  findAll(tenantId?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({ where, order: { created_at: 'DESC' }, relations: ['user'] });
  }

  async create(dto: { actual_weight: number; notes?: string }, userId?: string, tenantId?: string) {
    const statsQuery = this.productRepo
      .createQueryBuilder('p')
      .select('SUM(p.weight)', 'total')
      .where('p.status = :status', { status: ProductStatus.AVAILABLE });
    if (tenantId) statsQuery.andWhere('p.tenant_id = :tenantId', { tenantId });
    const stats = await statsQuery.getRawOne();

    const systemWeight = parseFloat(stats?.total || '0');
    const difference = dto.actual_weight - systemWeight;

    const check = this.repo.create({
      system_weight: systemWeight,
      actual_weight: dto.actual_weight,
      difference,
      notes: dto.notes,
      user_id: userId,
      tenant_id: tenantId || null,
    });

    return this.repo.save(check);
  }
}
