package game.scenes.con3.menagerie
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.entity.Dialog;
	import game.components.hit.EntityIdList;
	import game.components.hit.Item;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.scenes.con3.Con3Scene;
	import game.scenes.con3.shared.ElectricPulseGroup;
	import game.scenes.con3.shared.GauntletResponder;
	import game.scenes.con3.shared.laserPulse.LaserPulse;
	import game.scenes.con3.shared.rayReflect.ReflectToRayCollision;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Menagerie extends Con3Scene
	{
		public function Menagerie()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con3/menagerie/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function setUpScene():void
		{
			super.setUpScene();
			
			this.addSystem(new BitmapSequenceSystem());
			
			this.shellApi.eventTriggered.add(this.eventTriggered);
			
			setupPlayerDialog();
			setupSodaMachine();
			setupShieldBlocker();
			setupElfArcher();
			setupLaserTweaks();
			setupShieldItem();
		}
		
		private function setupLaserTweaks():void
		{
			var entity:Entity = this.getEntityById("lasersource_2_2");
			var pulse:LaserPulse = entity.get(LaserPulse);
			if(pulse)
			{
				pulse.timeOff += 2;
			}
		}
		
		private function setupPlayerDialog():void
		{
			var dialog:Dialog = this.player.get(Dialog);
			var data1:DialogData = dialog.allDialog["machine"];
			var data2:DialogData;
			
			data2 = dialog.allDialog["nice_gloves"];
			data2.dialog = data1.dialog;
			
			data2 = dialog.allDialog["no_power"];
			data2.dialog = data1.dialog;
		}
		
		private function setupElfArcher():void
		{
			if(!this.shellApi.checkEvent(_events.ELF_ARCHER_RESCUED) && !this.shellApi.checkEvent(_events.ELF_ARCHER_SPOTTED))		
			{
				SceneUtil.lockInput(this);
				SceneUtil.addTimedEvent(this, new TimedEvent( 1, 1, viewActor));
				
				shellApi.completeEvent( _events.ELF_ARCHER_SPOTTED );
			}
		}
		
		private function viewActor():void
		{
			var elfArcher:Entity = getEntityById("elf_archer");
			SceneUtil.setCameraTarget(this, elfArcher);
			
			var dialog:Dialog = elfArcher.get(Dialog);
			dialog.sayById( "help" );
			dialog.faceSpeaker = false;
			dialog.complete.addOnce(unlock);
		}
		
		private function unlock(...args):void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player);
		}
		
		private function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == GameEvent.GOT_ITEM + _events.OLD_SHIELD)
			{
				this.setupShieldBlocker();
			}
		}
		
		private function setupShieldBlocker():void
		{
			if(!this.shellApi.checkHasItem(_events.OLD_SHIELD))
			{
				var shield:Entity = this.getEntityById("old_shield");
				
				if(shield)
				{
					DisplayUtils.moveToBack(Display(shield.get(Display)).displayObject);
				}
				
				var entity:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer.addChild(new Sprite()));
				entity.add(new EntityIdList());
				entity.add(new Id("old_shield_reflect"));
				
				var spatial:Spatial = entity.get(Spatial);
				spatial.x = 2684;
				spatial.y = 867;
				spatial.rotation = 45;
				
				var reflect:ReflectToRayCollision = new ReflectToRayCollision();
				var graphics:Graphics = reflect.shape.graphics;
				graphics.clear();
				graphics.beginFill(0x0000FF);
				graphics.drawRect(-50, -5, 100, 10);
				graphics.endFill();
				entity.add(reflect);
			}
			else
			{
				this.removeEntity(this.getEntityById("old_shield_reflect"));
			}
		}
		
		private function setupShieldItem():void
		{
			var shield:Entity = this.getEntityById("old_shield");
			
			if(shield)
			{
				var laser:Entity = this.getEntityById("lasersource_3_1");
				Timeline(laser.get(Timeline)).labelReached.add(onLabelReached);
			}
		}
		
		private function onLabelReached(label:String):void
		{
			var shield:Entity = this.getEntityById("old_shield");
			
			if(shield)
			{
				if(label == "onEnd")
				{
					shield.remove(Item);
				}
				else if(label == "offEnd")
				{
					shield.add(new Item());
				}
			}
			else
			{
				var laser:Entity = this.getEntityById("lasersource_3_1");
				Timeline(laser.get(Timeline)).labelReached.remove(onLabelReached);
			}
		}
		
		private function setupSodaMachine():void
		{
			var machine:Entity = BitmapTimelineCreator.createBitmapTimeline(this._hitContainer["soda_machine"]);
			machine.add(new Id("soda_machine"));
			Timeline(machine.get(Timeline)).gotoAndStop(0);
			this.addEntity(machine);
			
			var glow:Entity = EntityUtils.createMovingEntity(this, this._hitContainer["soda1"]);
			TimelineUtils.convertClip(this._hitContainer["soda1"], this, glow, null, false);
			glow.add(new Id("soda1"));
			
			if(!this.shellApi.checkEvent(_events.GOT_SODA + "3"))
			{
				var pulseGroup:ElectricPulseGroup = this.addChildGroup(new ElectricPulseGroup()) as ElectricPulseGroup;
				pulseGroup.createPanels(this._hitContainer["panel1"], this, this._hitContainer, onPulse, "soda");
				
				var gauntletResponder:GauntletResponder = glow.get(GauntletResponder);
				gauntletResponder.offset.setTo(-30, 0);
			}
			else
			{
				Timeline(machine.get(Timeline)).gotoAndStop("dispenseEnd");
				Timeline(glow.get(Timeline)).gotoAndPlay("on");
			}
		}
		
		private function onPulse(responder:Entity):void
		{
			if(!this.shellApi.checkEvent(this._events.GOT_SODA + "3"))
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "soda_machine_dispense_01.mp3", 1, false, [SoundModifier.EFFECTS]);
				
				var machine:Entity = this.getEntityById("soda_machine");
				Timeline(machine.get(Timeline)).gotoAndPlay("dispense");
				Timeline(machine.get(Timeline)).handleLabel("dispenseEnd", onSodaDispensed);
				
				Timeline(responder.get(Timeline)).gotoAndPlay("on");
			}
		}
		
		private function onSodaDispensed():void
		{
			this.shellApi.completeEvent(this._events.GOT_SODA + "3");
			this.shellApi.completeEvent(this._events.HAS_SODA + "3");
			
			if(shellApi.checkHasItem(_events.SODA))
			{
				shellApi.showItem(_events.SODA, null);
			}
			else
			{
				shellApi.getItem(_events.SODA, null, true);
			}
		}
		
		override protected function freeActor():void
		{
			var elfArcher:Entity = this.getEntityById("elf_archer");
			CharUtils.setAnim(elfArcher, Stand, false, 30, 0, true);
			var dialog:Dialog = elfArcher.get(Dialog);
			dialog.faceSpeaker = true;
			dialog.allowOverwrite = true;
			dialog.sayById("punishment");
			dialog.complete.add(dialogComplete);
		}
		
		private function dialogComplete(data:DialogData):void
		{
			if(data.id == "hq")
			{
				var elfArcher:Entity = this.getEntityById("elf_archer");
				SceneUtil.setCameraTarget(this, elfArcher);
				CharUtils.followPath(elfArcher, new <Point>[new Point(632, 462), new Point(262, 916)], onPathComplete);
				DisplayUtils.moveToTop( Display( elfArcher.get( Display )).displayObject );
			}
		}
		
		private function onPathComplete(entity:Entity):void
		{
			SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, elfArcherRescued));
		}
		
		private function elfArcherRescued():void
		{
			this.shellApi.completeEvent(_events.ELF_ARCHER_RESCUED);
			this.removeEntity(this.getEntityById("elf_archer"));
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, this.player);
		}
	}
}