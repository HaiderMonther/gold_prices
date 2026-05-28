import { Controller, Get, Put, Param, UseGuards, Request } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  findAll(@Request() req: any) {
    const tenantId = req.user?.tenantId;
    return this.notificationsService.findAll(tenantId);
  }

  @Put('read-all')
  markAllAsRead(@Request() req: any) {
    const tenantId = req.user?.tenantId;
    return this.notificationsService.markAllAsRead(tenantId);
  }

  @Put(':id/read')
  markAsRead(@Param('id') id: string, @Request() req: any) {
    const tenantId = req.user?.tenantId;
    return this.notificationsService.markAsRead(id, tenantId);
  }
}
