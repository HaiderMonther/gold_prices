import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Tenant } from '../tenants/tenant.entity';
@Entity('gold_prices')
export class GoldPrice {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price_24k: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price_21k: number;

  @Column({ type: 'decimal', precision: 12, scale: 2 })
  price_18k: number;

  @Column({ nullable: true })
  updated_by: string;

  @ManyToOne(() => User, (u) => u.gold_prices, { nullable: true })
  @JoinColumn({ name: 'updated_by' })
  updated_by_user: User;

  @CreateDateColumn()
  created_at: Date;

  @ManyToOne(() => Tenant, { nullable: true })
  @JoinColumn({ name: 'tenant_id' })
  tenant: Tenant;

  @Column({ nullable: true })
  tenant_id: string;
}
