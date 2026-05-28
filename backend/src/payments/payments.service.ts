import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { ZaincashService } from './zaincash.service';
import { TenantsService } from '../tenants/tenants.service';

@Injectable()
export class PaymentsService {
  constructor(
    private readonly zaincashService: ZaincashService,
    private readonly tenantsService: TenantsService
  ) {}

  async createSubscriptionCheckout(tenantId: string, plan: string): Promise<{ paymentUrl: string }> {
    const tenant = await this.tenantsService.findOne(tenantId);
    if (!tenant) throw new NotFoundException('Tenant not found');

    const amount = plan === 'yearly' ? 500000 : 50000; // 500k IQD yearly, 50k IQD monthly
    const orderId = `${tenantId}-${Date.now()}`;
    const redirectUrl = `http://localhost:5173/payment/callback`; // Should come from config in prod

    const paymentUrl = await this.zaincashService.initTransaction(amount, orderId, redirectUrl);
    return { paymentUrl };
  }

  async verifyPaymentCallback(token: string): Promise<{ success: boolean; tenantId?: string }> {
    const data = this.zaincashService.decodeToken(token);
    if (!data) throw new BadRequestException('Invalid token');

    if (data.status === 'success') {
      const orderIdParts = data.orderid.split('-');
      const tenantId = orderIdParts.slice(0, orderIdParts.length - 1).join('-');
      
      // Activate the tenant!
      await this.tenantsService.update(tenantId, { is_active: true });
      return { success: true, tenantId };
    }

    return { success: false };
  }
}
