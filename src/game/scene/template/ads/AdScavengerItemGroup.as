package game.scene.template.ads
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.data.ads.AdTrackingConstants;
	import game.managers.ads.AdManager;
	import game.scene.template.PlatformerGameScene;
	import game.scene.template.ads.AdBaseGroup;
	import game.util.SceneUtil;
		
	/**
	 * Scavenger Item group for main street scenes
	 * @author Rick Hocker
	 */
	public class AdScavengerItemGroup extends AdBaseGroup
	{
		/**
		 * Constructor 
		 * @param container
		 * @param adManager
		 */
		public function AdScavengerItemGroup(container:DisplayObjectContainer=null, adManager:AdManager = null)
		{
			super(container, adManager);
			this.id = GROUP_ID;
		}
		
		/**
		 * Prepare scavenger item
		 * @param scene
		 * @return Boolean (true means ad group gets added to scene)
		 */
		override public function prepAdGroup(scene:PlatformerGameScene):Boolean
		{
			super.prepAdGroup(scene);
			
			// if scene doesn't already have ad scavenger group
			if (_parentScene.getGroupById(GROUP_ID) == null)
			{
				// ad inventory tracking (if scene supports type)
				_adManager.track(AdTrackingConstants.AD_INVENTORY, AdTrackingConstants.TRACKING_AD_SPOT_PRESENTED, _adManager.scavengerItemType);
				
				// check if scavenger item is on this island
				_adData = _adManager.getAdData(_adManager.scavengerItemType, false, true);
				// if scaventer item found in CMS data, then load it
				if (_adData != null)
				{
					// will need to construct array from string values from _adData.campaign_file1 (swfName,x,y,rotation)
					// if contains pipe, then assumes more than one
					var groups:Array = _adData.campaign_file1.split("|");
					var items:Array = _adData.campaign_file2.split("|");
					var count:int = groups.length;
					for (var i:int = 0; i!= count; i++)
					{
						parseDatqAndLoad(groups[i], items[i]);
					}
					return true;
				}
			}
			// if scavenger item not found, then return false for no ad
			trace("AdScavengerItemGroup: no scavenger item to display");
			return false;
		}
		
		private function parseDatqAndLoad(group:String, itemNum:String):void
		{
			var params:Array = group.split(",");
			var swfFileName:String = params[0];
			var coords:Array = params.slice(1);
			var pathToSwf:String = shellApi.assetPrefix + "scavengerHuntItems/" + swfFileName;
			
			// load swf by name
			shellApi.loadFile(pathToSwf, swfLoaded, coords, itemNum);
		}

		/**
		 * When scavenger item swf is loaded 
		 * @param clip loaded swf
		 * coords coordinates for swf
		 * itemNum item number of card to be awarded
		 */
		private function swfLoaded(clip:MovieClip, coords:Array, itemNum:String):void
		{
			if (clip == null)
			{
				trace("Scavenger item failed to load!");
			}
			else
			{
				trace("Scavenger item load succeeded.");
				
				// place clip swf in scene based on coords
				clip.x = coords[0];
				clip.y = coords[1];
				if(coords.length == 3)
					clip.rotation = coords[2];
				_parentScene.hitContainer.addChild(clip);
				SceneUtil.CreateSceneItem(_parentScene, clip, itemNum);
				
				// impression tracking
				_adManager.track(_adData.campaign_name, AdTrackingConstants.TRACKING_IMPRESSION, _adData.campaign_type);			
			}
		}
				
		public static const GROUP_ID:String = "AdScavengerItemGroup";
	}
}