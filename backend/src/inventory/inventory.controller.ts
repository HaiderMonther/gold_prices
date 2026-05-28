import { Controller, Get, Post, Body, UseGuards, Request } from '@nestjs/common';
import { InventoryService } from './inventory.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('inventory')
@UseGuards(JwtAuthGuard)
export class InventoryController {
  constructor(private service: InventoryService) {}

  @Get() findAll(@Request() req: any) { return this.service.findAll(req.user?.tenantId); }
  @Post() create(@Body() dto: any, @Request() req: any) { return this.service.create(dto, req.user?.id, req.user?.tenantId); }
}
