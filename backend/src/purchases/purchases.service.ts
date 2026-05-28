import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Purchase } from './purchase.entity';

@Injectable()
export class PurchasesService {
  constructor(@InjectRepository(Purchase) private repo: Repository<Purchase>) {}

  findAll(tenantId?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({ where, order: { created_at: 'DESC' }, relations: ['user'] });
  }

  create(dto: any, userId?: string, tenantId?: string) {
    // Calculate equivalent 24k weight
    const eq24k = (dto.weight * dto.karat) / 24;
    return this.repo.save(this.repo.create({ ...dto, equivalent_24k: eq24k, user_id: userId, tenant_id: tenantId || null }));
  }

  async remove(id: string) {
    const p = await this.repo.findOne({ where: { id } });
    if (p) await this.repo.remove(p);
    return { message: 'تم الحذف' };
  }
}
