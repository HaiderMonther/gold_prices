import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Tenant } from '../tenants/tenant.entity';
export enum GoldType {
  NEW = 'new',
  USED = 'used',
  SCRAP = 'scrap',
}

@Entity('purchases')
export class Purchase {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  seller_name: string;

  @Column({ type: 'enum', enum: GoldType, default: GoldType.USED })
  gold_type: GoldType;

  @Column({ type: 'decimal', precision: 10, scale: 3 })
  weight: number;

  @Column()
  karat: number;

  @Column({ type: 'decimal', precision: 10, scale: 3 })
  equivalent_24k: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  market_price: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  paid_amount: number;

  @Column({ type: 'decimal', precision: 5, scale: 2, default: 0 })
  discount_percent: number;

  @Column({ nullable: true })
  user_id: string;

  @ManyToOne(() => User, (u) => u.purchases, { nullable: true })
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
