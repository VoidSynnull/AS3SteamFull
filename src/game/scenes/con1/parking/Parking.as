package game.scenes.con1.parking
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.game.GameEvent;
	import game.data.sound.SoundModifier;
	import game.scenes.con1.shared.Poptropicon1Scene;
	import game.scenes.con1.shared.RandomNPCCreator;
	import game.scenes.con1.shared.RandomNPCGroup;
	import game.scenes.con1.shared.popups.Booth;
	import game.util.AudioUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Parking extends Poptropicon1Scene
	{
		public function Parking()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con1/parking/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();			
		}
		
		override public function destroy():void
		{
			if(_randomGlint)
			{
				_randomGlint.stop();
				_randomGlint = null;
			}
			super.destroy();
		}
		
		// all assets ready
		override public function loaded():void
		{		
			super.loaded();			
			
			setupPizzaWheels();
			setupAnimations();
			setupCraftTable();	
			
			if(this.shellApi.checkItemEvent(_events.FREMULON_MASK))
			{
				this.removeFremulonMask();
			}
			else
			{
				this.convertContainer(_hitContainer.getChildByName("fremulonMask") as DisplayObjectContainer, 1);
			}
			
			if(!shellApi.checkItemEvent(_events.WATCH_PARTS))
			{
				_glint = EntityUtils.createDisplayEntity(this, _hitContainer["watchSparkle"]);
				_glint = TimelineUtils.convertClip(_hitContainer["watchSparkle"], this, _glint);
				randomGlint();
				DisplayUtils.moveToTop(_glint.get(Display).displayObject);
			}
			else
				_hitContainer.removeChild(_hitContainer["watchSparkle"]);
			
			var display:DisplayObject = Display(this.player.get(Display)).displayObject;
			var placement:Number = display.parent.getChildIndex(display);			
			var randomGroup:RandomNPCGroup = new RandomNPCGroup("randomNPC1", 1450, 1, 2, 0, 50, 200, 250, 4, placement);
			addChildGroup(randomGroup);
			
			var creator:RandomNPCCreator = new RandomNPCCreator(this, "scenes/con1/shared/randomNPC.xml");
			randomGroup.setup(_hitContainer, this, creator);
		}
		
		override public function handleEventTrigger(event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null):void
		{
			if(event == GameEvent.HAS_ITEM + _events.FREMULON_MASK)
			{
				this.removeFremulonMask();
			}
			else if(event == GameEvent.HAS_ITEM + _events.WATCH_PARTS)
			{
				if( _glint )
				{
					removeEntity(_glint);
				}
				if( _randomGlint )
				{
					_randomGlint.stop();
					_randomGlint = null;
				}
			}
			
			super.handleEventTrigger(event, makeCurrent, init, removeEvent);
		}
		
		private function removeFremulonMask():void
		{
			var mask:DisplayObject = _hitContainer.getChildByName("fremulonMask");
			if(mask)
			{
				mask.parent.removeChild(mask);
			}
		}
		
		private function randomGlint():void
		{
			_randomGlint = SceneUtil.addTimedEvent(this, new TimedEvent(Math.random() * 4, 1, playGlint));
		}
		
		private function playGlint():void
		{
			_glint.get(Timeline).gotoAndPlay("glint");
			randomGlint();
		}		
		
		private function setupPizzaWheels():void
		{
			for(var i:int = 0; i < NUM_WHEELS; i++)
			{
				var mc:MovieClip = _hitContainer["pizza" + i];
				var sprite:Sprite = this.createBitmapSprite(mc);
				
				var pizzaEntity:Entity = EntityUtils.createMovingEntity(this, sprite);
				pizzaEntity.add(new Audio());
				pizzaEntity.add(new AudioRange(900, 0, 1, Sine.easeIn));
				InteractionCreator.addToEntity(pizzaEntity, [InteractionCreator.CLICK]);
				Interaction(pizzaEntity.get(Interaction)).click.add(pizzaClicked);
				ToolTipCreator.addToEntity(pizzaEntity);
			}
		}		
		
		private function setupAnimations():void
		{			
			// just make sign timeline
			var signMC:MovieClip = _hitContainer["fremulon_sign"];
			
			DisplayUtils.moveToOverUnder(getEntityById("alien_guy").get(Display).displayObject, signMC, false);
			
			var entity:Entity = BitmapTimelineCreator.createBitmapTimeline(signMC);
			Timeline(entity.get(Timeline)).play();
			this.addEntity(entity);
			
			// Ship lights
			this.convertContainer(_hitContainer["shipLights"]);
			var ship:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["shipLights"]);
			ship = TimelineUtils.convertClip(_hitContainer["shipLights"], this, ship);
			InteractionCreator.addToEntity(ship, [InteractionCreator.CLICK]);
			ToolTipCreator.addToEntity(ship);
			ship.get(Interaction).click.add(shipClicked);
			
			// puffs
			var puffSequence:BitmapSequence = BitmapTimelineCreator.createSequence(_hitContainer["puff"]);
			for(var i:int = 0; i <= 2; i++)
			{
				var locMC:MovieClip = _hitContainer["puff" + i];
				var newPuff:Entity = BitmapTimelineCreator.createBitmapTimeline(_hitContainer["puff"], true, false, puffSequence)
				addEntity(newPuff);
				
				var spatial:Spatial = newPuff.get(Spatial);
				spatial.x = locMC.x;
				spatial.y = locMC.y;
				DisplayUtils.moveToBack(newPuff.get(Display).displayObject);
				
				InteractionCreator.addToEntity(newPuff, [InteractionCreator.CLICK]);
				if(!PlatformUtils.isMobileOS)
					ToolTipCreator.addToEntity(newPuff);
				newPuff.get(Interaction).click.add(puffClicked);
			}
			_hitContainer.removeChild(_hitContainer["puff"]);
			
			// soda can
			var soda:Entity = BitmapTimelineCreator.createBitmapTimeline(_hitContainer["sodaCan"]);
			this.addEntity(soda);	
			InteractionCreator.addToEntity(soda, [InteractionCreator.CLICK]);
			if(!PlatformUtils.isMobileOS)
				ToolTipCreator.addToEntity(soda);
			soda.get(Interaction).click.add(sodaFizzle);	
		}
		
		private function setupCraftTable():void
		{
			var craft:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["craftClick"]);
			InteractionCreator.addToEntity(craft, [InteractionCreator.CLICK]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.add(openBoothPopup);
			craft.add(sceneInteraction).add( new Id("craftClick" ));
			ToolTipCreator.addToEntity(craft);
		}
		
		private function pizzaClicked(pizza:Entity):void
		{			
			var motion:Motion = pizza.get(Motion);
			if(motion.rotationVelocity == 0)
			{
				pizza.get(Audio).play(SoundManager.EFFECTS_PATH + "gears_05b_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
				motion.rotationVelocity = 300;
			}
			else
			{
				pizza.get(Audio).stop(SoundManager.EFFECTS_PATH + "gears_05b_loop.mp3");
				motion.rotationVelocity = 0;
			}
		}
		
		private function shipClicked(ship:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "power_on_08.mp3");
			ship.get(Timeline).gotoAndPlay("lights");
		}
		
		private function puffClicked(puff:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "flesh_impact_06.mp3");
			puff.get(Timeline).gotoAndPlay("puff");
		}
		
		private function sodaFizzle(soda:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "soda_can_open_01.mp3");
			soda.get(Timeline).gotoAndPlay("fizzle");
		}
		
		private function openBoothPopup(clicker:Entity, clicked:Entity):void
		{
			var booth:Booth = new Booth( overlayContainer );
			booth.fail.addOnce( failDialog );
			booth.victory.addOnce( getJetpack );
			
			addChildGroup( booth );
		}
		
		private function failDialog( booth:Booth, dialogId:String ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( dialogId );
		}
		
		private function getJetpack( booth:Booth ):void
		{
			shellApi.getItem( _events.JETPACK, null, true );
			
			removeEntity( getEntityById( "craftClick" ));
		}
		
		private static var NUM_WHEELS:int = 2;
		private var _glint:Entity;
		private var _randomGlint:TimedEvent;
	}
}