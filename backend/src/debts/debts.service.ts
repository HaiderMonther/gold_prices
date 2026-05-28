import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Debt } from './debt.entity';
import { Customer } from '../customers/customer.entity';

@Injectable()
export class DebtsService {
  constructor(
    @InjectRepository(Debt) private repo: Repository<Debt>,
    @InjectRepository(Customer) private customerRepo: Repository<Customer>,
  ) {}

  findAll(tenantId?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({
      where,
      order: { created_at: 'DESC' },
      relations: ['customer', 'invoice'],
    });
  }

  findUnpaid(tenantId?: string) {
    const where: any = { is_paid: false };
    if (tenantId) where.tenant_id = tenantId;
    return this.repo.find({
      where,
      relations: ['customer', 'invoice'],
    });
  }

  async payDebt(id: string, amount: number) {
    const debt = await this.repo.findOne({ where: { id } });
    if (!debt) throw new NotFoundException('الدين غير موجود');

    debt.paid_amount = parseFloat(debt.paid_amount as any) + amount;
    if (debt.paid_amount >= parseFloat(debt.amount as any)) {
      debt.is_paid = true;
      debt.paid_amount = parseFloat(debt.amount as any);
    }

    await this.repo.save(debt);

    // Update customer debt balance
    await this.customerRepo.decrement({ id: debt.customer_id }, 'debt_balance', amount);

    return debt;
  }
}
