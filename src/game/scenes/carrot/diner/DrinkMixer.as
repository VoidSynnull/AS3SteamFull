package game.scenes.carrot.diner
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.motion.SpatialToMouse;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.sound.SoundModifier;
	import game.data.ui.TransitionData;
	import game.scenes.carrot.diner.components.Glass;
	import game.scenes.carrot.diner.systems.MixerSystem;
	import game.systems.motion.SpatialToMouseSystem;
	import game.ui.popup.Popup;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class DrinkMixer extends Popup
	{
		public var sendDrink:Signal = new Signal(uint); //Used to return a hair color value back to Diner.as
		
		private var _handles:Vector.<Entity> = new Vector.<Entity>();
		
		private var _currentSpout:Entity;
		private var _currentHandle:Entity;
		private var _glass:Glass;
		
		private const POURING:String = "pouring_drink_01.mp3";
		private const BUTTON:String = "button_01.mp3";
		
		public function DrinkMixer(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			this.sendDrink.removeAll();
			this.sendDrink = null;

			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// setup the transitions 
			this.transitionIn = new TransitionData();
			this.transitionIn.duration = .3;
			this.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			this.transitionOut = super.transitionIn.duplicateSwitch();
			
			this.darkenBackground = true;
			this.autoOpen = true;
			this.groupPrefix = "scenes/carrot/diner/drinkMixerPopup/";
			this.screenAsset = "drinkmixer.swf";
			super.init(container);
			
			this.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			this.loadCloseButton();
			this.layout.centerUI(this.screen.content);
			
			var mixerSystem:MixerSystem = new MixerSystem();
			mixerSystem.complete.add( glassFull );
			this.addSystem( mixerSystem );
					
			setupMachines();
			setupGlass();
			
			//For some reason, this is pixelated ONLY on desktop(?)...
			if(PlatformUtils.isMobileOS)
			{
				ButtonCreator.createButtonEntity(this.screen.content.btnDrink, this, onClick, null, null, null, true, true, 2);
			}
			else
			{
				ButtonCreator.createButtonEntity(this.screen.content.btnDrink, this, onClick);
			}
			
		}
		
		private function setupMachines():void
		{
			var clip:MovieClip;
			var button:Entity;
			var audio:Audio;
			var audioRange:AudioRange;
			
			for(var i:uint = 1; i <= 5; i++)
			{
				clip = this.screen.content["m" + i];
				
				button = ButtonCreator.createButtonEntity(clip["hit"], this);
				TimelineUtils.convertClip(clip["handle"], this, button, null, false);
				
				button.add(new Id("handle" + i));
				
				var emitter:Spout = new Spout();
				switch(i)
				{
					case 1: emitter.init(0xFF0000FF); break;
					case 2: emitter.init(0xFFFF0000); break;
					case 3: emitter.init(0xFFFFFF00); break;
					case 4: emitter.init(0xFF000000); break;
					case 5: emitter.init(0xFFFFFFFF); break;
					default: emitter.init(0xFF00FF00); break;
				}
				audio = new Audio();
				audioRange = new AudioRange( 400, 0, 1 );
				button.add( audio ).add( audioRange );
				
				var spout:Entity = EmitterCreator.create(this, clip, emitter, 0, 0, null, "spout" + i);
				Emitter(spout.get(Emitter)).stop = true;
				Emitter(spout.get(Emitter)).emitter.counter.stop();
				
				var bubbles:Bubbles = new Bubbles();
				bubbles.init(0.75);
				EmitterCreator.create(this, clip, bubbles, 0, -75, null, "bubbles" + i);
				
				var interaction:Interaction = button.get(Interaction);
				interaction.up.add(Command.create(onHandleUp, spout));
				interaction.out.add(Command.create(onHandleUp, spout));
				interaction.down.add(Command.create(onHandleDown, spout));
			}
		}
		
		private function glassFull( ):void
		{
			Emitter(_currentSpout.get(Emitter)).emitter.counter.stop();
			Timeline(_currentHandle.get(Timeline)).gotoAndStop("up");
			
			if(this._glass.isFilling)
			{
				this._glass.isFilling = false;
		//		AudioUtils.play(this, SoundManager.EFFECTS_PATH + "button_02.mp3", 1, false, [SoundModifier.EFFECTS]);
			}
		}
		
		private function onHandleDown( handle:Entity, spout:Entity ):void
		{
			if( this._glass.isFull ) 
			{
				return;
			}
			this._glass.isFilling = true;
			
			Emitter(spout.get(Emitter)).start = true;
			Emitter(spout.get(Emitter)).emitter.counter.resume();
			
			_currentSpout = spout;
			_currentHandle = handle;
			
			var id:String = Id( handle.get( Id )).id;
			this._glass.machine = uint(id.charAt(id.length-1));
			
			var audio:Audio = handle.get( Audio );
			/**
			 * The sound needs to forcibly be stopped before it starts playing again. This is because any
			 * fading sound kills any new sound of the same url that starts. Bleh.
			 */
			
			audio.play( SoundManager.EFFECTS_PATH + POURING, true, [SoundModifier.EFFECTS]);
			audio.play( SoundManager.EFFECTS_PATH + BUTTON, false, [SoundModifier.EFFECTS]);
		}
		
		private function onHandleUp( handle:Entity, spout:Entity ):void
		{
			this._glass.isFilling = false;
			var audio:Audio = handle.get( Audio );
			Emitter(spout.get(Emitter)).emitter.counter.stop();
			
			audio.stop( SoundManager.EFFECTS_PATH + POURING);
		}
		
		private function onClick(entity:Entity):void
		{
			//Send drink color back to scene.
			var color:ColorTransform = this._glass.color;
			sendDrink.dispatch(ColorUtil.rgbToHex(color.redOffset, color.greenOffset, color.blueOffset ));
			
			super.close();
		}
		
		private function setupGlass():void
		{
			var clip:MovieClip = this.screen.content.glass;
			clip["colorClip"].scaleY = 0;
			
			this.addSystem(new SpatialToMouseSystem());
			
			var followEntity:Entity = EntityUtils.createSpatialEntity(this);
			followEntity.add(new SpatialToMouse(clip.parent));
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			entity.add(EntityUtils.createTargetSpatial(followEntity));
			EntityUtils.followTarget(entity, followEntity, 0.1, new Point(0, 0), false, new <String> ["x"]);
			
			this._glass = new Glass();
			entity.add(this._glass);
			
			var bubbles:Bubbles = new Bubbles();
			bubbles.init(1.25);
			EmitterCreator.create(this, MovieClip(clip.colorClip), bubbles, 0, 0, null, "glassBubbles");
		}
	}
}