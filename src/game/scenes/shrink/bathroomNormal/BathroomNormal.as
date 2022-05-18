package game.scenes.shrink.bathroomNormal
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	
	import game.components.hit.Zone;
	import game.components.motion.Threshold;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.mainStreet.StreamerSystem.StreamerSystem;
	import game.systems.SystemPriorities;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class BathroomNormal extends PlatformerGameScene
	{
		public function BathroomNormal()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/bathroomNormal/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private var shrinkRay:ShrinkEvents;
		
		override protected function addBaseSystems():void
		{
			addSystem( new ThresholdSystem());
			
			super.addBaseSystems();
		}
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			shrinkRay = events as ShrinkEvents;
			
			setUpCat();
		}
		
		private function setUpCat():void
		{
			if( shellApi.checkEvent( shrinkRay.CAT_IN_BATH ) && !shellApi.checkEvent( shrinkRay.CHASED_CAT ))
			{
				setUpCatTrigger();
			}
			else
			{
				removeEntity(getEntityById("cat"));
			}
		}
		
		private function setUpCatTrigger():void
		{
			var catSpatial:Spatial = getEntityById( "cat" ).get( Spatial );
			var threshold:Threshold = new Threshold( "x", "<=" );
			threshold.threshold = 250;
			threshold.entered.addOnce( runOutBath );
			player.add( threshold );
//			var trigger:MovieClip = new MovieClip();
//			trigger.graphics.beginFill(0, 0);
//			trigger.graphics.lineTo(250, 0);
//			trigger.graphics.lineTo(250, - 1000);
//			trigger.graphics.lineTo(0, -1000);
//			trigger.graphics.lineTo(0,0);
//			trigger.graphics.endFill();
//			trigger.x = catSpatial.x;
//			trigger.y = catSpatial.y;
//			
//			var entity:Entity = EntityUtils.createSpatialEntity(this, trigger, _hitContainer);
//			Display(entity.get(Display)).moveToBack();
//			entity.add(new Id("catTrigger"));
//			entity.add(new Zone());
//			var zone:Zone = entity.get(Zone);
//			zone.entered.add(runOutBath);
		}
		
		private function runOutBath(...args ):void//zone:String, triggerer:String):void
		{
//			if(triggerer != "player")
//				return;
			var cat:Entity = getEntityById( "cat" );
			SceneUtil.lockInput( this );
			var catTarget:Spatial = getEntityById( "doorApartmentNormal" ).get( Spatial );
			CharUtils.moveToTarget( cat, catTarget.x, catTarget.y, false, getCat );
		}
		
		private function getCat(entity:Entity):void
		{
			SceneUtil.lockInput( this, false );
			shellApi.completeEvent( shrinkRay.CHASED_CAT );
			removeEntity( entity );
		}
	}
}