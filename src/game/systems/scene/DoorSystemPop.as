package game.systems.scene
{
	import ash.core.Entity;
	
	import game.components.hit.Door;
	import game.data.ads.AdCampaignType;
	import game.data.ads.AdTrackingConstants;
	import game.managers.ads.AdManager;

	public class DoorSystemPop extends DoorSystem
	{
		public function DoorSystemPop()
		{
			super();
		}
		
		override protected function doorReached(openingEntity:Entity, doorEntity:Entity):void
		{
			var door:Door = doorEntity.get(Door);
			door.open = true;
			
			// ad specific stuff
			if(_shellApi.adManager)
			{
				if (door.data.adDoor)
				{
					AdManager(_shellApi.adManager).doorReached(openingEntity, doorEntity);	
				}
				
				// ad inventory tracking
				if (door.data.skipAdType)
				{
					AdManager(_shellApi.adManager).track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, door.data.skipAdType);
					// if skipping main street, then add main street wrapper
					if (door.data.skipAdType.indexOf(AdCampaignType.MAIN_STREET) != -1)
						AdManager(_shellApi.adManager).track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, "Wrapper On Main");
				}
			}
		}
	}
}