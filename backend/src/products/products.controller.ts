import { Controller, Get, Post, Put, Delete, Param, Body, Query, UseGuards, Request } from '@nestjs/common';
import { ProductsService } from './products.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ProductStatus } from './product.entity';

@Controller('products')
@UseGuards(JwtAuthGuard)
export class ProductsController {
  constructor(private service: ProductsService) {}

  @Get() findAll(@Query('status') status?: ProductStatus, @Request() req?: any) { return this.service.findAll(status, req?.user?.tenantId); }
  @Get('stats') stats(@Request() req: any) { return this.service.getInventoryStats(req.user?.tenantId); }
  @Get('barcode/:barcode') findByBarcode(@Param('barcode') bc: string) { return this.service.findByBarcode(bc); }
  @Get(':id') findOne(@Param('id') id: string) { return this.service.findOne(id); }
  @Post() create(@Body() dto: any, @Request() req: any) { return this.service.create(dto, req.user?.id, req.user?.tenantId); }
  @Put(':id') update(@Param('id') id: string, @Body() dto: any) { return this.service.update(id, dto); }
  @Delete(':id') remove(@Param('id') id: string) { return this.service.remove(id); }
}
