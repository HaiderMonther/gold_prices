import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Customer } from './customer.entity';

@Injectable()
export class CustomersService {
  constructor(@InjectRepository(Customer) private repo: Repository<Customer>) {}

  findAll(tenantId?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({ where, order: { created_at: 'DESC' } });
  }

  async findOne(id: string) {
    const c = await this.repo.findOne({ where: { id }, relations: ['invoices', 'debts'] });
    if (!c) throw new NotFoundException('العميل غير موجود');
    return c;
  }

  create(dto: Partial<Customer>, tenantId?: string) {
    return this.repo.save(this.repo.create({ ...dto, tenant_id: tenantId || null }));
  }

  async update(id: string, dto: Partial<Customer>) {
    await this.findOne(id);
    await this.repo.update(id, dto);
    return this.repo.findOne({ where: { id } });
  }

  async remove(id: string) {
    const c = await this.findOne(id);
    await this.repo.remove(c);
    return { message: 'تم حذف العميل' };
  }

  async updateDebtBalance(customerId: string, amount: number) {
    await this.repo.increment({ id: customerId }, 'debt_balance', amount);
  }
}
