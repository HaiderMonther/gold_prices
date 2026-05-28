import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, MoreThanOrEqual, LessThanOrEqual } from 'typeorm';
import { CashBox, CashBoxType, CashBoxRefType } from './cash-box.entity';

@Injectable()
export class CashBoxService {
  constructor(
    @InjectRepository(CashBox) private repo: Repository<CashBox>,
  ) {}

  async findAll(tenantId?: string, dateFrom?: string, dateTo?: string) {
    const where: any = {};
    if (tenantId) where.tenant_id = tenantId;
    if (dateFrom && dateTo) {
      where.created_at = Between(new Date(dateFrom), new Date(dateTo + 'T23:59:59'));
    } else if (dateFrom) {
      where.created_at = MoreThanOrEqual(new Date(dateFrom));
    } else if (dateTo) {
      where.created_at = LessThanOrEqual(new Date(dateTo + 'T23:59:59'));
    }
    return this.repo.find({
      where,
      relations: ['user'],
      order: { created_at: 'DESC' },
    });
  }

  async getBalance(tenantId?: string): Promise<number> {
    const query = this.repo
      .createQueryBuilder('cb')
      .select(`SUM(CASE WHEN cb.type = 'deposit' THEN cb.amount ELSE -cb.amount END)`, 'balance');
    if (tenantId) query.where('cb.tenant_id = :tenantId', { tenantId });
    const result = await query.getRawOne();
    return parseFloat(result?.balance || '0');
  }

  async getDailySummary(tenantId?: string, date?: string) {
    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    const where: any = { created_at: Between(startOfDay, endOfDay) };
    if (tenantId) where.tenant_id = tenantId;

    const entries = await this.repo.find({
      where,
      relations: ['user'],
      order: { created_at: 'ASC' },
    });

    const deposits = entries
      .filter(e => e.type === CashBoxType.DEPOSIT)
      .reduce((s, e) => s + parseFloat(String(e.amount)), 0);
    const withdrawals = entries
      .filter(e => e.type === CashBoxType.WITHDRAWAL)
      .reduce((s, e) => s + parseFloat(String(e.amount)), 0);

    return {
      date: startOfDay.toISOString().split('T')[0],
      entries,
      deposits,
      withdrawals,
      net: deposits - withdrawals,
      balance: await this.getBalance(tenantId),
    };
  }

  async addEntry(data: {
    type: CashBoxType;
    amount: number;
    description: string;
    reference_type?: CashBoxRefType;
    reference_id?: string;
    user_id?: string;
    tenant_id?: string;
  }) {
    const currentBalance = await this.getBalance(data.tenant_id);
    const newBalance = data.type === CashBoxType.DEPOSIT
      ? currentBalance + data.amount
      : currentBalance - data.amount;

    const entry = this.repo.create({
      ...data,
      reference_type: data.reference_type || CashBoxRefType.MANUAL,
      balance_after: newBalance,
    });

    return this.repo.save(entry);
  }

  async recordSale(invoiceId: string, amount: number, userId?: string, tenantId?: string) {
    return this.addEntry({
      type: CashBoxType.DEPOSIT,
      amount,
      description: `تحصيل فاتورة بيع`,
      reference_type: CashBoxRefType.SALE,
      reference_id: invoiceId,
      user_id: userId,
      tenant_id: tenantId,
    });
  }

  async recordPurchase(purchaseId: string, amount: number, userId?: string, tenantId?: string) {
    return this.addEntry({
      type: CashBoxType.WITHDRAWAL,
      amount,
      description: `دفع مقابل شراء ذهب`,
      reference_type: CashBoxRefType.PURCHASE,
      reference_id: purchaseId,
      user_id: userId,
      tenant_id: tenantId,
    });
  }

  async recordExpense(expenseId: string, amount: number, description: string, userId?: string, tenantId?: string) {
    return this.addEntry({
      type: CashBoxType.WITHDRAWAL,
      amount,
      description: `مصروف: ${description}`,
      reference_type: CashBoxRefType.EXPENSE,
      reference_id: expenseId,
      user_id: userId,
      tenant_id: tenantId,
    });
  }

  async recordDebtPayment(debtId: string, amount: number, userId?: string, tenantId?: string) {
    return this.addEntry({
      type: CashBoxType.DEPOSIT,
      amount,
      description: `تحصيل دين`,
      reference_type: CashBoxRefType.DEBT_PAYMENT,
      reference_id: debtId,
      user_id: userId,
      tenant_id: tenantId,
    });
  }
}
