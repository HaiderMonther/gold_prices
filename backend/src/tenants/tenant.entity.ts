import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('tenants')
export class Tenant {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  // Unique code that clients enter at login (replaces subdomain)
  @Column({ unique: true })
  tenant_code: string;

  // Optional: kept for backward compatibility, nullable now
  @Column({ unique: true, nullable: true })
  subdomain: string;

  @Column({ nullable: true })
  logo_url: string;

  @Column({ nullable: true })
  primary_color: string;

  @Column({ default: true })
  is_active: boolean;

  @CreateDateColumn()
  created_at: Date;

  @UpdateDateColumn()
  updated_at: Date;
}
