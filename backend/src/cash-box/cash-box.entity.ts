import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Tenant } from '../tenants/tenant.entity';
export enum CashBoxType {
  DEPOSIT = 'deposit',
  WITHDRAWAL = 'withdrawal',
}

export enum CashBoxRefType {
  SALE = 'sale',
  PURCHASE = 'purchase',
  EXPENSE = 'expense',
  DEBT_PAYMENT = 'debt_payment',
  TRANSFER = 'transfer',
  MANUAL = 'manual',
  OPENING_BALANCE = 'opening_balance',
}

@Entity('cash_box')
export class CashBox {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'enum', enum: CashBoxType })
  type: CashBoxType;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  amount: number;

  @Column()
  description: string;

  @Column({ type: 'enum', enum: CashBoxRefType, default: CashBoxRefType.MANUAL })
  reference_type: CashBoxRefType;

  @Column({ nullable: true })
  reference_id: string;

  @Column({ type: 'decimal', precision: 12, scale: 2, default: 0 })
  balance_after: number;

  @Column({ nullable: true })
  user_id: string;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'user_id' })
  user: User;

  @CreateDateColumn()
  created_at: Date;

  @ManyToOne(() => Tenant, { nullable: true })
  @JoinColumn({ name: 'tenant_id' })
  tenant: Tenant;

  @Column({ nullable: true })
  tenant_id: string;
}
