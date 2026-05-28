import { Module } from '@nestjs/common';
import { PaymentsController } from './payments.controller';
import { PaymentsService } from './payments.service';
import { ZaincashService } from './zaincash.service';
import { TenantsModule } from '../tenants/tenants.module';

@Module({
  imports: [TenantsModule],
  controllers: [PaymentsController],
  providers: [PaymentsService, ZaincashService],
  exports: [PaymentsService, ZaincashService],
})
export class PaymentsModule {}
