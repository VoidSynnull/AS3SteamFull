package game.scenes.carnival.hauntedLab{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.entity.Sleep;
	import game.components.hit.Item;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.islands.carnival.AddFlashlightEffect;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carnival.CarnivalEvents;
	import game.scenes.carnival.hauntedLab.components.PuppetMonster;
	import game.scenes.carnival.hauntedLab.systems.PuppetMonsterSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.TimelineUtils;
	
	public class HauntedLab extends PlatformerGameScene
	{
		private var _monster:Entity;
		private var _events:CarnivalEvents;
		
		public function HauntedLab()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carnival/hauntedLab/";
			
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
			_events = new CarnivalEvents();
			
			if ( super.shellApi.checkHasItem(_events.FLASHLIGHT) || super.shellApi.checkHasItem(_events.FLASHLIGHT_BLACK)) 
			{
				//let's make the user equip the flashlight manually
				//SkinUtils.setSkinPart(player, SkinUtils.ITEM, "mc_flashlight_normal", false);
			}
			else 
			{
				//make fly mask unobtainable, if it is still in scene
				var fly_mask:Entity = super.getEntityById("fly_mask");
				if( fly_mask != null )
				{
					ToolTipCreator.removeFromEntity( fly_mask );
					fly_mask.remove(SceneInteraction);
					fly_mask.remove(Interaction);
					fly_mask.remove(Item);
					EntityUtils.getDisplay(fly_mask).moveToBack();
				}
			}
			
			var black_lightbulb:Entity = super.getEntityById("black_lightbulb");
			if( black_lightbulb != null )
			{
				if ( !super.shellApi.checkHasItem(_events.SECRET_MESSAGE) ) 
				{
					ToolTipCreator.removeFromEntity( black_lightbulb );
					black_lightbulb.remove(SceneInteraction);
					black_lightbulb.remove(Interaction);
					black_lightbulb.remove(Item);
				}
				EntityUtils.getDisplay(black_lightbulb).moveToBack();
			}
			
			//CharUtils.addSpecialAbility(super.player, new SpecialAbilityData(AddFlashlightEffect));
			var specialData:SpecialAbilityData = new SpecialAbilityData(AddFlashlightEffect);
			specialData.triggerable = false;
			CharUtils.addSpecialAbility(super.player, specialData, true);
			
			if (super.shellApi.checkEvent(_events.MONSTERS_UNLEASHED) ) 
			{
				addSystem(new PuppetMonsterSystem(), SystemPriorities.move);
				super.loadFile("puppetMonster.swf", setupMonster);
			}
			else 
			{
				setupCages( true );
				super.loaded()
			}	
		}
		
		private function setupCages( makeStatic:Boolean = false ):Vector.<Entity>
		{
			var clip:MovieClip;
			var entity:Entity;
			var cageEntities:Vector.<Entity>;
			
			var i:uint = 0;
			for ( i; i<7; i++ ) 
			{
				clip = hitContainer["cage" + i];
				if( makeStatic )
				{
					clip.gotoAndStop(1);
				}
				else
				{
					if( cageEntities == null )	{ cageEntities = new Vector.<Entity>(); }
					entity = EntityUtils.createSpatialEntity( this, clip );
					TimelineUtils.convertClip(clip, this, entity);
					entity.add( new Id("cage" + i) );
					cageEntities.push(entity);
				}
			}
			return cageEntities;
		}
		
		private function setupMonster(clip:MovieClip):void
		{
			//set up cages
			var cageEntities:Vector.<Entity> = setupCages( false );

			_monster = EntityUtils.createMovingEntity( this, clip.content, hitContainer );
			TimelineUtils.convertClip(clip.content, this, _monster, null, false);
			TimelineUtils.convertClip(clip.content.head, this, null, _monster, false).add( new Id("head"));
			_monster.add(new Sleep( false, true));
			_monster.add( new PuppetMonster(new Point(500, 1200), cageEntities) );
			Motion(_monster.get(Motion)).friction = new Point(800, 800);
			
			// position puppet at first cage
			var cage0:Entity = cageEntities[0];
			EntityUtils.position(_monster, cage0.get(Spatial).x, cage0.get(Spatial).y);
			
			//audio
			var monsterAudio:Audio = new Audio();
			_monster.add(monsterAudio);
			_monster.add(new AudioRange(800, 0, 1, Quad.easeIn));
			
			Timeline(_monster.get(Timeline)).gotoAndPlay("leave");
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			
			DisplayUtils.moveToTop( _monster.get(Display).displayObject );	// position puppet over player
			super.loaded()
		}
	}
}





