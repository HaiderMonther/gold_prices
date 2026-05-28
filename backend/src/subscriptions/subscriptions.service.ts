import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Subscription, SubscriptionStatus } from './subscription.entity';
import { Tenant } from '../tenants/tenant.entity';

@Injectable()
export class SubscriptionsService {
  constructor(
    @InjectRepository(Subscription)
    private subRepo: Repository<Subscription>,
    @InjectRepository(Tenant)
    private tenantRepo: Repository<Tenant>,
  ) {}

  async createSubscription(tenantId: string, planName: string, durationMonths: number) {
    const startDate = new Date();
    const endDate = new Date();
    endDate.setMonth(endDate.getMonth() + durationMonths);

    const sub = this.subRepo.create({
      tenant_id: tenantId,
      plan_name: planName,
      status: SubscriptionStatus.ACTIVE,
      start_date: startDate,
      end_date: endDate,
    });
    
    await this.subRepo.save(sub);
    await this.tenantRepo.update(tenantId, { is_active: true });
    
    return sub;
  }

  async checkExpiredSubscriptions() {
    const now = new Date();
    const expiredSubs = await this.subRepo.find({
      where: {
        status: SubscriptionStatus.ACTIVE,
      },
    });

    const toDeactivate = expiredSubs.filter(sub => sub.end_date && sub.end_date < now);

    for (const sub of toDeactivate) {
      sub.status = SubscriptionStatus.EXPIRED;
      await this.subRepo.save(sub);
      
      // Deactivate tenant
      if (sub.tenant_id) {
        await this.tenantRepo.update(sub.tenant_id, { is_active: false });
      }
    }

    return toDeactivate.length;
  }
}
