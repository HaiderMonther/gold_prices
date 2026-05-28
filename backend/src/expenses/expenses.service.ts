import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Expense } from './expense.entity';

@Injectable()
export class ExpensesService {
  constructor(@InjectRepository(Expense) private repo: Repository<Expense>) {}

  findAll(tenantId?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({ where, order: { created_at: 'DESC' }, relations: ['user'] });
  }

  create(dto: any, userId?: string, tenantId?: string) {
    return this.repo.save(this.repo.create({ ...dto, user_id: userId, tenant_id: tenantId || null }));
  }

  async remove(id: string) {
    const e = await this.repo.findOne({ where: { id } });
    if (e) await this.repo.remove(e);
    return { message: 'تم حذف المصروف' };
  }

  async getStats(tenantId?: string) {
    const query = this.repo
      .createQueryBuilder('e')
      .select('e.category', 'category')
      .addSelect('SUM(e.amount)', 'total')
      .groupBy('e.category');
    if (tenantId) query.where('e.tenant_id = :tenantId', { tenantId });
    return query.getRawMany();
  }
}
