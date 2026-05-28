import {
  Entity, PrimaryGeneratedColumn, Column, CreateDateColumn,
  ManyToOne, JoinColumn,
} from 'typeorm';
import { User } from '../users/user.entity';
import { Tenant } from '../tenants/tenant.entity';
@Entity('inventory_checks')
export class InventoryCheck {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'decimal', precision: 10, scale: 3 })
  system_weight: number;

  @Column({ type: 'decimal', precision: 10, scale: 3 })
  actual_weight: number;

  @Column({ type: 'decimal', precision: 10, scale: 3 })
  difference: number;

  @Column({ nullable: true })
  notes: string;

  @Column({ nullable: true })
  user_id: string;

  @ManyToOne(() => User, (u) => u.inventory_checks, { nullable: true })
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
