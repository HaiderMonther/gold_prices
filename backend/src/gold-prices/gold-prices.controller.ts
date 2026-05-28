import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { GoldPricesService } from './gold-prices.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('gold-prices')
@UseGuards(JwtAuthGuard)
export class GoldPricesController {
  constructor(private service: GoldPricesService) {}

  @Get() findAll(@Request() req: any) { return this.service.findAll(req.user?.tenantId); }
  @Get('latest') getLatest(@Request() req: any) { return this.service.getLatest(req.user?.tenantId); }
  @Post() create(@Body() dto: any, @Request() req: any) {
    return this.service.create(dto, req.user?.id, req.user?.tenantId);
  }
}
