import { Controller, Get } from '@nestjs/common';
import { ApiOkResponse, ApiTags } from '@nestjs/swagger';
import { PLAN_IDS, PLANS, type PlanConfig } from '@gleefy/plans';
import { Public } from '../auth/decorators';

@ApiTags('plans')
@Controller('plans')
export class PlansController {
  /** Plans with their entitlements and indicative prices (the store charges the real amount). */
  @Get()
  @Public()
  @ApiOkResponse({ description: 'Plans, least to most generous' })
  list(): PlanConfig[] {
    return PLAN_IDS.map((id) => PLANS[id]);
  }
}
