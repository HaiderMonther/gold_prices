import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './notification.entity';

@Injectable()
export class NotificationsService {
  constructor(
    @InjectRepository(Notification)
    private repo: Repository<Notification>,
  ) {}

  async findAll(tenantId?: string) {
    const whereClause = tenantId ? { tenant_id: tenantId } : {};
    return await this.repo.find({
      where: whereClause,
      order: { created_at: 'DESC' },
      take: 50, // Limit to recent 50
    });
  }

  async create(dto: {
    title: string;
    message: string;
    type?: string;
    icon?: string;
    tenant_id?: string;
  }) {
    const notification = this.repo.create(dto);
    return await this.repo.save(notification);
  }

  async markAllAsRead(tenantId?: string) {
    const whereClause = tenantId ? { tenant_id: tenantId, is_read: false } : { is_read: false };
    await this.repo.update(whereClause, { is_read: true });
    return { success: true };
  }

  async markAsRead(id: string, tenantId?: string) {
    const whereClause: any = { id };
    if (tenantId) whereClause.tenant_id = tenantId;
    
    await this.repo.update(whereClause, { is_read: true });
    return { success: true };
  }
}
