package game.scenes.arab3.palaceInterior
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.hit.Door;
	import game.components.motion.Destination;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.components.ui.ToolTip;
	import game.components.ui.ToolTipActive;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.PointItem;
	import game.scene.template.AudioGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.arab3.Arab3Scene;
	import game.scenes.viking.diningHall.DiningHall;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class PalaceInterior extends Arab3Scene
	{
		private const LIGHT:String		= "light";
		private const FLAME:String		= "flame";
		private const TRIGGER:String 	= "trigger";
		
		private var sultan:Entity;
		private var tileClick:Entity;
		private var tileClickInteraction:Interaction;
		
		private var atriumDoor:Entity;
		private var doorAtrium:Entity;
		private var door:MovieClip;
		private var doorOpen:Boolean = false;
		private var atriumDoorInteraction:Interaction;
		private var atriumDoorToolTip:ToolTip;
		
		public function PalaceInterior()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			super.groupPrefix = "scenes/arab3/palaceInterior/";
			super.init( container );
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
			sultan = this.getEntityById("sultan");
			
			if(shellApi.checkEvent(_events.SULTAN_LEFT)){
				this.removeEntity(sultan);
				//setupTile();
			}
			if(shellApi.checkEvent(_events.HIDDEN_DOOR_OPENED)){
				doorOpen = true;
			} //else {
			//_hitContainer['tileClick'].visible = false;
			//}
			setupAssets();
			setupTile();
			setupAtriumDoor();
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "sultanLeave" ) {
				CharUtils.moveToTarget(sultan, 1803, 775, false, sultanLeft);
			} else if( event == "lockScene" ) {
				SceneUtil.lockInput(this,true);
			} 
		}
		
		private function sultanLeft(entity:Entity):void
		{
			SceneUtil.lockInput(this,false);
			this.removeEntity(sultan);
			this.shellApi.completeEvent(_events.SULTAN_LEFT);
			//setupTile();
		}
		
		private function setupAssets():void
		{
			var entity:Entity;
			var clip:MovieClip;
			var sequence:BitmapSequence;
			var flameSequence:BitmapSequence;
			var number:int;
			
			//SETUP CANDLE LIGHTS
			clip = _hitContainer[ LIGHT + "1" ];
			sequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
			clip = _hitContainer[ FLAME + "1" ];
			flameSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
			if( !_audioGroup )
			{
				_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			}
			for( number = 1; number <= 2; number ++ )
			{
				// LIGHT ANIMATION
				clip = _hitContainer[ LIGHT + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
				Timeline( entity.get( Timeline )).playing = true;
				
				// FLAME ANIMATION
				clip = _hitContainer[ FLAME + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				entity.add( new AudioRange( 400 ));
				_audioGroup.addAudioToEntity( entity );
				Audio( entity.get( Audio )).playCurrentAction( TRIGGER );
				
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, flameSequence, PerformanceUtils.defaultBitmapQuality );
				Timeline( entity.get( Timeline )).playing = true;
			}
			
			//SETUP DOOR ANIMATION
			//clip = _hitContainer[ "windowDoor" ];
			//entity = EntityUtils.createSpatialEntity( this, clip );
			//entity.add( new Id( clip.name ));
			//door = BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, null, PerformanceUtils.defaultBitmapQuality );
			
		}
		
		private function setupTile():void
		{
			tileClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["tileClick"]), this);
			tileClick.remove(Button);
			//tileClick.remove(Timeline);
			tileClickInteraction = tileClick.get(Interaction);
			tileClickInteraction.downNative.add( Command.create( clickTile ));
			//tileClick.get(Display).alpha = 0;
			
			door = _hitContainer["windowDoor"]["door"];
			
		}		
		
		private function clickTile(event:Event):void
		{
			var destination:Destination = CharUtils.moveToTarget(player, 320, 620, false, getCloser);
			destination.ignorePlatformTarget = true;
		}
		
		private function getCloser(entity:Entity):void {
			CharUtils.moveToTarget(player, 310, 704, false, wait);
		}
		
		private function wait(entity:Entity):void {
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5, 1, pressTile));
		}
		
		private function pressTile(entity:Entity=null):void {
			CharUtils.setDirection(player, false);
			CharUtils.setAnim(player, PointItem);
			player.get(Timeline).handleLabel("pointing", openDoor, true);
		}
		
		private function openDoor(entity:Entity=null):void
		{
			tileClick.get(Timeline).gotoAndStop("down");
			SceneUtil.addTimedEvent(this, new TimedEvent(0.25, 1, buttonUp));
			if(doorOpen){
				atriumDoor.remove( ToolTip );
				atriumDoorInteraction.lock = true;
				TweenUtils.globalTo(this, door, 1, {y:-26, ease:Sine.easeInOut}, "door_close");
				doorAtrium.get(Display).displayObject.mouseChildren = false;
				doorAtrium.get(Display).displayObject.mouseEnabled = false;
				doorOpen = false;
				
			} else {
				atriumDoor.add( atriumDoorToolTip );
				atriumDoorInteraction.lock = false;
				TweenUtils.globalTo(this, door, 1, {y:-130, ease:Sine.easeInOut}, "door_open");
				doorAtrium.get(Display).displayObject.mouseChildren = true;
				doorAtrium.get(Display).displayObject.mouseEnabled = true;
				doorOpen = true;
				
			}
			if(!shellApi.checkEvent(_events.HIDDEN_DOOR_OPENED)){
				shellApi.completeEvent(_events.HIDDEN_DOOR_OPENED);
			}
		}
		
		private function buttonUp():void {
			tileClick.get(Timeline).gotoAndStop("over");
		}
		
		private function setupAtriumDoor():void
		{
			doorAtrium = super.getEntityById("doorAtrium");
			atriumDoor = doorAtrium.get(Children).children[0];
			var interaction:Interaction = doorAtrium.get(Interaction);
			atriumDoorInteraction = interaction;
			atriumDoorToolTip = atriumDoor.get(ToolTip);
			
			if(!doorOpen) {
				doorAtrium.get(Display).displayObject.mouseChildren = false;
				doorAtrium.get(Display).displayObject.mouseEnabled = false;			
				
				atriumDoorInteraction.lock = true;
				atriumDoor.remove(ToolTip);
			} else {
				doorAtrium.get(Display).displayObject.mouseChildren = true;
				doorAtrium.get(Display).displayObject.mouseEnabled = true;
				
				atriumDoorInteraction.lock = false;
				this.door.y = -130;
			}
		}
	}
}