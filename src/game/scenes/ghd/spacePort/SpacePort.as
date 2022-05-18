package game.scenes.ghd.spacePort
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Character;
	import game.creators.entity.BitmapTimelineCreator;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.ghd.GalacticHotDogEvents;
	import game.scenes.ghd.GalacticHotDogScene;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	
	public class SpacePort extends GalacticHotDogScene
	{
		public function SpacePort()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/spacePort/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(1185, 1010),"minibillboard/minibillboardMedLegs.swf");	

			this.shellApi.setUserField(_events.PLANET_FIELD, _events.SPACE_PORT, this.shellApi.island, true);
			
			var ghdEvents:GalacticHotDogEvents = this.events as GalacticHotDogEvents;
			if(!this.shellApi.checkEvent(ghdEvents.STARTED))
			{
				this.shellApi.completeEvent(ghdEvents.STARTED);
				SceneUtil.removeIslandParts(this);
				
			}
			
			correctAlienDialogPositioning();
			
			setupAnimations();
		}
		
		private function setupAnimations():void
		{
			var clip:MovieClip = _hitContainer["bolt"];
			var bolt:Entity;
			bolt = EntityUtils.createMovingTimelineEntity(this, clip, null, true);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				bolt = BitmapTimelineCreator.convertToBitmapTimeline(bolt, null, true, null, PerformanceUtils.defaultBitmapQuality);
			}
			clip = _hitContainer["sign"];
			var sign:Entity;	
			sign = EntityUtils.createMovingTimelineEntity(this, clip, null, true);
			if(PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH){
				sign = BitmapTimelineCreator.convertToBitmapTimeline(sign, null, true, null, PerformanceUtils.defaultBitmapQuality);
			}
		}
		
		private function correctAlienDialogPositioning():void
		{	
			var aliens:Vector.<Entity> = new <Entity>[ getEntityById( "alien1" )
				, getEntityById( "alien2" )
				, getEntityById( "alien4" )];
			var dialog:Dialog;
			var positions:Vector.<Point> = new <Point>[ new Point( 0, .5 )
				, new Point( 0, 1 )
				, new Point( 0, .5 )];
			
			for( var number:int = 0; number < aliens.length; number ++ )
			{
				dialog = aliens[ number ].get( Dialog );
				dialog.dialogPositionPercents = positions[ number ];
				Character(aliens[number].get(Character)).costumizable = false;
			}
		}
	}
}