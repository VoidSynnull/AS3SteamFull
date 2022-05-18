package game.scenes.arab3.vizierRoom
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Skin;
	import game.components.motion.Destination;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Wave;
	import game.scene.template.AudioGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.arab3.Arab3Scene;
	import game.scenes.arab3.vizierRoom.particles.LevitationBlast;
	import game.scenes.arab3.vizierRoom.popups.AlchemyTable2;
	import game.scenes.arab3.vizierRoom.popups.BookshelfPopup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	import org.osflash.signals.Signal;
	
	public class VizierRoom extends Arab3Scene
	{
		private const LIGHT:String		= "light";
		private const FLAME:String		= "flame";
		private const TRIGGER:String 	= "trigger";
		
		private var _bottleSequence:BitmapSequence;
		private var _carpetSequence:BitmapSequence;
		private var _flameSequence:BitmapSequence;
		private var _lightSequence:BitmapSequence;
		
		private var alchemyClick:Entity;
		private var alchemyClickInteraction:Interaction;
		
		private var bookshelfClick:Entity;
		private var bookshelfClickInteraction:Interaction;
		
		private var bookshelfPopup:BookshelfPopup;
		
		private var carpet:Entity;
		private var bottle:Entity;
		private var brokenTable:Entity;
		
		private var smokeEmitter:LevitationBlast;
		private var smokeEmitterEntity:Entity;
		
		public function VizierRoom()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			super.groupPrefix = "scenes/arab3/vizierRoom/";
			super.init( container );
		}
		
		override public function destroy():void
		{
			if( _bottleSequence )
			{
				_bottleSequence.destroy();
				_bottleSequence= null;
			}
			if( _carpetSequence )
			{
				_carpetSequence.destroy();
				_carpetSequence= null;
			}
			if( _flameSequence )
			{
				_flameSequence.destroy();
				_flameSequence= null;
			}
			if( _lightSequence )
			{
				_lightSequence.destroy();
				_lightSequence= null;
			}
			super.destroy();
		}
		
		override public function loaded():void
		{
			super.loaded();
			super.shellApi.eventTriggered.add(handleEventTriggered);	
			
//			if(shellApi.checkHasItem(_events.DIVINATION_DUST)){
//				_hitContainer.removeChild( _hitContainer['tableDiv']);
//			}
//			else
//			{
//				super.convertContainer( _hitContainer['tableDiv'], PerformanceUtils.defaultBitmapQuality );
//			}
			
			if(shellApi.checkHasItem(_events.MAGIC_CARPET)){
				_hitContainer.removeChild( _hitContainer['table']);
				_hitContainer.removeChild( _hitContainer['carpet']);				
				_hitContainer.removeChild( _hitContainer['bottle']);
				
				super.convertContainer( _hitContainer['brokenTable'], PerformanceUtils.defaultBitmapQuality );
			} else {
				setupCarpet();
			}
			
			setupBookshelf();
			setupAlchemyTable();
			setupAssets();
		}
		
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void {
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			if( event == "getInstructions" ) {
				bookshelfPopup.popupRemoved.addOnce(bookshelfPopupClosed);
				bookshelfPopup.close();
			}
			else if(event == "gotItem_"+_events.DIVINATION_DUST){
				
			}
			else if(event == "gotItem_"+_events.MAGIC_CARPET){
				
			} else if ( event == "runBack") {
				runBackFromCarpet();
			}  else if ( event == "magicCarpet") {
				awardMagicCarpet();
			}
		}
		
		private function setupAlchemyTable():void
		{
			alchemyClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["alchemyClick"]), this);
			alchemyClick.remove(Timeline);
			alchemyClickInteraction = alchemyClick.get(Interaction);
			alchemyClickInteraction.downNative.add( Command.create( clickAlchemyTable ));
			alchemyClick.get(Display).alpha = 0;
		}		
		
		private function clickAlchemyTable(event:Event):void
		{
			var destination:Destination = CharUtils.moveToTarget(player, 716, 927, false, waitForAlchemyTable);
			destination.ignorePlatformTarget = true;
		}
		
		private function waitForAlchemyTable(entity:Entity):void {
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,openAlchemyTable));
		}
		
		private function openAlchemyTable():void {
			CharUtils.setDirection(player, true);
			if(!shellApi.checkHasItem(_events.MAGIC_BOOK)){
				handleAlchemyResult("noBook");
			} else {
				if(!shellApi.checkHasItem(_events.MAGIC_CARPET)){
					var popup:AlchemyTable2 = super.addChildGroup(new AlchemyTable2(super.overlayContainer)) as AlchemyTable2;
					popup.id = "alchemy_table";
					popup.completeSignal = new Signal();
					popup.completeSignal.addOnce(handleAlchemyResult);
					SceneUtil.lockInput(this, false);
				} else {
					Dialog(player.get(Dialog)).sayById("noUse");
					SceneUtil.lockInput( this, false );
				}
			}
		}
		
		private function handleAlchemyResult(result:String):void
		{
			// handle what happened in the popup, trigger getting magic carpet or divination dust item or hand
			if(result == "noBook"){
				Dialog(player.get(Dialog)).sayById("noBook");
				SceneUtil.lockInput(this,false);
				//testCarpet(); //ONLY FOR TESTING
			}
			else if(result == _events.DIVINATION_DUST){
				shellApi.getItem(_events.DIVINATION_DUST,null,true);
	//			_hitContainer.removeChild( _hitContainer['tableDiv']);//.visible = false;
			}
			else if(result == _events.MAGIC_CARPET){
				SceneUtil.lockInput(this, true);
	//			_hitContainer.removeChild( _hitContainer['tableLev']);//.visible = false; //hide bottle on table
				Dialog(player.get(Dialog)).sayById("didIt");
				CharUtils.setAnim(player, Wave);
				
				bottle.get(Display).visible = true;
				
				var hand:Entity = Skin( player.get( Skin )).getSkinPartEntity( "hand2" );
				var handDisplay:Display = hand.get( Display );
				
				handDisplay.displayObject.addChildAt(bottle.get(Display).displayObject, 0);
				
				bottle.get(Spatial).x = 0;
				bottle.get(Spatial).y = 0;
				bottle.get(Spatial).scale = 2;
				
				smokeEmitter = new LevitationBlast();
				smokeEmitter.init();
				
				smokeEmitterEntity = EmitterCreator.create( this, super._hitContainer, smokeEmitter, 0, 0, player, "sEmitterEntity", bottle.get(Spatial), false );
				
				SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, tossBottle));
			}
			else{
				Dialog(player.get(Dialog)).sayById("fail");
			}
		}
		
		private function tossBottle():void {
			CharUtils.setAnim(player, Grief);
			_hitContainer.addChild(bottle.get(Display).displayObject);
			bottle.get(Spatial).scale = 1;
			bottle.get(Spatial).x = player.get(Spatial).x + 24;
			bottle.get(Spatial).y = player.get(Spatial).y - 24;
			var botTargY:Number = bottle.get(Spatial).y - 100;
			DisplayUtils.moveToBack(bottle.get(Display).displayObject);
			TweenUtils.globalTo(this,bottle.get(Spatial),1,{rotation:"700", ease:Sine.easeInOut},"bottle_rotate");
			TweenUtils.globalTo(this,bottle.get(Spatial),0.5,{y:botTargY, ease:Sine.easeOut, onComplete: bottleDown},"bottle_up");
		}
		
		private function bottleDown(event:Event=null):void {
			TweenUtils.globalTo(this,bottle.get(Spatial),0.5,{delay:0.5, y:920, ease:Sine.easeIn, onComplete: sayWhoops},"bottle_down");
		}
		
		private function sayWhoops():void {
			Dialog(player.get(Dialog)).sayById("whoops");
			bottle.get(Spatial).rotation = 0;
			bottle.get(Timeline).gotoAndPlay("break");
			shellApi.triggerEvent("breakBottle");
			smokeEmitter.start();
			
			_hitContainer.removeChild( _hitContainer[ "table" ]);
			Display( brokenTable.get( Display )).visible = true;
		}
		
		private function runBackFromCarpet(event:Event=null):void {
			CharUtils.moveToTarget(player, 521, 927, false, carpetAwake);
		}
		
		private function carpetAwake(entity:Entity):void {
			DisplayUtils.moveToTop( Display( carpet.get( Display )).displayObject );
			CharUtils.setDirection(player, true);
			bottle.get(Display).visible = false;
			TweenUtils.globalTo(this,carpet.get(Spatial),4,{delay:1, y:900, ease:Sine.easeInOut, onComplete:sayMagicCarpet},"levitate");
			carpet.get(Timeline).gotoAndPlay("startLevitate");
		}
		
		private function sayMagicCarpet():void {
			Dialog(player.get(Dialog)).sayById("magicCarpet");
		}
		
		private function awardMagicCarpet():void {
			SceneUtil.lockInput(this, false);
			shellApi.getItem(_events.MAGIC_CARPET, null, true );
			this.removeEntity(carpet);
		}
		
//		public function testCarpet():void {
//			handleAlchemyResult(_events.MAGIC_CARPET);
//		}
		
		private function setupBookshelf():void
		{
			bookshelfClick = ButtonCreator.createButtonEntity(MovieClip(MovieClip(_hitContainer)["bookshelfClick"]), this);
			bookshelfClick.remove(Timeline);
			bookshelfClickInteraction = bookshelfClick.get(Interaction);
			bookshelfClickInteraction.downNative.add( Command.create( clickBookshelf ));
			bookshelfClick.get(Display).alpha = 0;
		}	
		
		private function clickBookshelf(event:Event):void
		{
			var destination:Destination = CharUtils.moveToTarget(player, 291, 657, false, waitForBookshelf);
			destination.ignorePlatformTarget = true;
		}
		
		private function waitForBookshelf(entity:Entity):void {
			SceneUtil.lockInput(this, true);
			SceneUtil.addTimedEvent(this, new TimedEvent(0.5,1,openBookshelf));
		}
		
		private function openBookshelf():void
		{
			bookshelfPopup = new BookshelfPopup(overlayContainer);
			
			addChildGroup(bookshelfPopup);
			SceneUtil.lockInput(this, false);
		}
		
		private function bookshelfPopupClosed():void {
			shellApi.getItem(_events.INSTRUCTIONS, null, true );
		}
		
		private function setupCarpet():void {
			var clip:MovieClip = _hitContainer["carpet"];
			_carpetSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality )
				
			carpet = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline( carpet, clip, true, _carpetSequence );
			carpet.get(Timeline).gotoAndStop(0);
			//carpet.get(Timeline).gotoAndPlay("startLevitate");
			
			clip = _hitContainer["bottle"];	
			_bottleSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality )
				
			bottle = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			BitmapTimelineCreator.convertToBitmapTimeline( bottle, clip, true, _bottleSequence );
			bottle.get(Timeline).gotoAndStop(0);
			bottle.get(Display).visible = false;
			
			clip = _hitContainer["brokenTable"];
			super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality );
			
			brokenTable = EntityUtils.createSpatialEntity( this, clip );
			Display( brokenTable.get( Display )).visible = false;
		}
		
		private function setupAssets():void
		{
			var entity:Entity;
			var clip:MovieClip;
			var number:int;
			
			//SETUP CANDLE LIGHTS
			clip = _hitContainer[ LIGHT + "1" ];
			_lightSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
			clip = _hitContainer[ FLAME + "1" ];
			_flameSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
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
				
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, _lightSequence, PerformanceUtils.defaultBitmapQuality );
				Timeline( entity.get( Timeline )).playing = true;
				
				// FLAME ANIMATION
				clip = _hitContainer[ FLAME + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( clip.name ));
				entity.add( new AudioRange( 400 ));
				_audioGroup.addAudioToEntity( entity );
				Audio( entity.get( Audio )).playCurrentAction( TRIGGER );
				
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, _flameSequence, PerformanceUtils.defaultBitmapQuality );
				Timeline( entity.get( Timeline )).playing = true;
			}
		}
	}
}