import { Module } from '@nestjs/common';
import { SubscriptionCronService } from './subscription-cron.service';
import { SubscriptionsModule } from '../subscriptions/subscriptions.module';

@Module({
  imports: [SubscriptionsModule],
  providers: [SubscriptionCronService],
})
export class CronModule {}
