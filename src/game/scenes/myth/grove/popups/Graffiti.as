package game.scenes.myth.grove.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.data.TimedEvent;
	import game.data.sound.SoundModifier;
	import game.scenes.survival1.shared.components.BitmapClean;
	import game.scenes.survival1.shared.systems.BitmapCleanSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.SceneUtil;
	
	import org.osflash.signals.Signal;
	
	public class Graffiti extends Popup
	{
		public function Graffiti( grafNum:int, container:DisplayObjectContainer=null )
		{
			_grafNum = grafNum;
			super( container );
		}
		
		override public function destroy():void
		{
			complete.removeAll();
			complete = null;
			
			super.destroy();	
		}
		
		override public function init( container:DisplayObjectContainer=null ):void
		{
			complete = new Signal();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/myth/grove/";
			super.init( container );
			super.autoOpen = false;
			load();
		}
		
		override public function load():void
		{
			super.loadFiles([ "graffiti" + _grafNum + ".swf" ], false, true, loaded );
		}
		
		override public function loaded():void
		{
			super.screen = super.getAsset( "graffiti" + _grafNum + ".swf", true ) as MovieClip;
			super.layout.centerUI( super.screen.content );
		
			var number:int;
			loadCloseButton();
			
			super.loaded();
			super.open();
			
			this.setupCleaning();
		}
		
		private function setupCleaning():void
		{
			this.addSystem(new BitmapCleanSystem());
			
			var entity:Entity = new Entity();
			this.addEntity(entity);
			
			var sprite:Sprite = this.convertToBitmapSprite(this.screen.content.graf).sprite;
			
			var display:Display = new Display( sprite, sprite.parent );
			entity.add(display);
			
			InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN, InteractionCreator.UP, InteractionCreator.RELEASE_OUT]);
//			var minPercent:Number;
//			
//			switch( _grafNum )
//			{
//				case 0:
//					minPercent = 1;
//					break;
//				case 1:
//					minPercent = 1;
//					break;
//				case 2:
//					minPercent = 1.01;
//					break;
//				default:
//					break;
//			}
			var clean:BitmapClean = new BitmapClean( 38, .996 );
			clean.waitTime = .05;
			clean.startCleaning.add(startCleaning);
			clean.stopCleaning.add(stopCleaning);
			clean.cleaned.add(onCleaned);
			entity.add(clean);
		}
		
		private function startCleaning(entity:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "myth_graffiti_wash_loop_01.mp3", 1, true, [SoundModifier.EFFECTS]);
		}
		
		private function stopCleaning(entity:Entity):void
		{
			AudioUtils.stop(this, SoundManager.EFFECTS_PATH + "myth_graffiti_wash_loop_01.mp3");
		}
		
		private function onCleaned(entity:Entity):void
		{
			SceneUtil.lockInput( this );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, completeGraffiti ));
		}
		
		public function completeGraffiti():void
		{
			complete.dispatch();
		}
		
		public function getNumber():int
		{
			return _grafNum;
		}
		
		public var complete:Signal;
	
		public var startX:Number;
		public var startY:Number;
		
		private var _grafNum:int;
	}
}