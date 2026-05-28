import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { GoldPrice } from './gold-price.entity';

@Injectable()
export class GoldPricesService {
  constructor(@InjectRepository(GoldPrice) private repo: Repository<GoldPrice>) {}

  async findAll(tenantId?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({ where, order: { created_at: 'DESC' }, take: 30, relations: ['updated_by_user'] });
  }

  async getLatest(tenantId?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    const results = await this.repo.find({
      where,
      order: { created_at: 'DESC' },
      take: 1,
      relations: ['updated_by_user'],
    });
    return results[0] || null;
  }

  async create(dto: { price_24k: number; price_21k: number; price_18k: number }, userId?: string, tenantId?: string) {
    const gp = this.repo.create({ ...dto, updated_by: userId, tenant_id: tenantId || null });
    return this.repo.save(gp);
  }
}
