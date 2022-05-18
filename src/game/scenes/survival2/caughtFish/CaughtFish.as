package game.scenes.survival2.caughtFish
{
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.animation.entity.character.Stand;
	import game.data.comm.PopResponse;
	import game.data.profile.ProfileData;
	import game.scene.template.CutScene;
	import game.scene.template.CutSubScene;
	import game.scenes.survival2.Survival2Events;
	import game.scenes.time.shared.emitters.Fire;
	import game.scenes.time.shared.emitters.FireSmoke;
	import game.ui.popup.IslandEndingPopup;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class CaughtFish extends CutScene
	{
		private var _loop:int = 0;
		
		private const SPIN:String = "gritty_spin_01_loop.mp3";
		private const FIRE:String = "fire_05_L.mp3";
		private const WATER:String = "lapping_water.mp3";
		
		private const NEW_LINE:String = "\n";
		private const LETTERS_PER_LINE:int = 13;
		
		private var survival:Survival2Events;
		
		private var _scene1:CutSubScene; //Forest Eating
		private var _scene2:CutSubScene; //Tree Camera
		private var _scene3:CutSubScene; //Buren Monitors
		
		public function CaughtFish()
		{
			super();
			configData("scenes/survival2/caughtFish/");
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			survival = shellApi.islandEvents as Survival2Events;
			
			var name:String = "fireInteraction";
			var fire:Fire = new Fire();
			fire.init( 3, new RectangleZone( -13, -4, 13, -4 ));
			EmitterCreator.create(this, screen.scene1["background"][ "campFire" ], fire );
			var smoke:FireSmoke = new FireSmoke();
			smoke.init( 9, new LineZone( new Point( -2, -20 ), new Point( 2, -40 )), new RectangleZone( -10, -50, 10, -5 ));
			EmitterCreator.create(this, screen.scene1["background"][ "campFire" ], smoke );			
			var fireEnt:Entity = getEntityById(name);
		}
		
		override protected function addSystems():void
		{
			super.addSystems();
			
			//Have to do this here because it's after the screen is loaded and set, and before it's bitmapped...
			carveTree();
		}
		
		override protected function convertScreen():Entity
		{
			_scene3 = this.addChildGroup(new CutSubScene()) as CutSubScene; 
			_scene3.setup( _screen["scene3"], null, playNext, true, true );
			Timeline(_scene3.subSceneEntity.get(Timeline)).labelReached.add(onLabelReached);
			
			_scene2 = this.addChildGroup(new CutSubScene()) as CutSubScene; 
			_scene2.setup( _screen["scene2"], _scene3, playNext, true, true );
			Timeline(_scene2.subSceneEntity.get(Timeline)).labelReached.add(onLabelReached);
			
			_scene1 = this.addChildGroup(new CutSubScene()) as CutSubScene; 
			_scene1.setup( _screen["scene1"], _scene2, playNext, true, true );
			Timeline(_scene1.subSceneEntity.get(Timeline)).labelReached.add(onLabelReached);
			
			return null;
		}
		
		private function playNext(current:CutSubScene, next:CutSubScene = null):void
		{
			if(current == _scene3)
			{
				setEntityContainer(player, screen.scene3.playerholder.player_container);
			}
			
			if(next)
			{
				next.start();
			}
			else
			{
				this.end();
			}
		}
		
		override public function start(...args):void
		{
			this.groupReady();
			_scene1.start();
		}
		
		override public function setUpCharacters():void
		{
			setEntityContainer(player, screen.scene1.playerholder.player_container);
			SkinUtils.emptySkinPart( player, SkinUtils.ITEM, false );
			
			var colorHex:Number = ColorUtil.darkenColor( SkinUtils.getSkinPart(player, SkinUtils.SKIN_COLOR).value, .15 );		
			var myColorTransform:ColorTransform = new ColorTransform();
			myColorTransform.color = colorHex;
			screen.scene1.background.poparm.transform.colorTransform = myColorTransform; 		
			
			EntityUtils.visible( CharUtils.getPart( player, CharUtils.ARM_BACK ), false );
			EntityUtils.visible( CharUtils.getPart( player, CharUtils.HAND_BACK ), false );
			
			CharUtils.setAnim(player, Stand);
			CharUtils.getTimeline( player ).gotoAndStop( 5 );
			SkinUtils.setSkinPart( player, SkinUtils.MOUTH, "chew",false );
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "fish_stick",false, start );
			
			sceneAudio.play(SoundManager.EFFECTS_PATH + SPIN, true, null, .5);
			sceneAudio.play(SoundManager.EFFECTS_PATH + FIRE, true, null, .8);
			sceneAudio.play(SoundManager.AMBIENT_PATH + WATER, true);
		}
		
		private function cameraShowSound():void
		{
			sceneAudio.setVolume(.5, "ambient", WATER);
			sceneAudio.setVolume(.2, "effects", SPIN);
			sceneAudio.setVolume(.4, "effects", FIRE);
		}
		
		private function cameraFocusSound():void
		{
			sceneAudio.stop(SoundManager.AMBIENT_PATH + WATER);
			sceneAudio.stop(SoundManager.EFFECTS_PATH + SPIN);
			sceneAudio.stop(SoundManager.EFFECTS_PATH + FIRE);
		}
		
		private function carveTree():void
		{
			var text:TextField = super.screen.scene3.background2.screens.treeTrunk.grafiti.grafiti;
			
			var profile:ProfileData = shellApi.profileManager.active;
			
			var format:TextFormat = text.defaultTextFormat;
			
			format.align =  TextFormatAlign.LEFT;
			
			text.defaultTextFormat = format;
			
			var words:Vector.<String> = new Vector.<String>();
			words.push(profile.avatarFirstName, profile.avatarLastName, "WAS", "HERE");
			
			var fullText:String = "";
			
			for(var i:int = 0; i < words.length; i++)
			{
				fullText += String(createCenteredWord(words[i]) + NEW_LINE).toUpperCase();
			}
			
			if(shellApi.checkEvent(survival.ENGRAVED_NAME))
				text.text = fullText;
		}
		
		private function createCenteredWord(name:String):String
		{
			if( DataUtils.validString( name ) )
			{
				var spaces:int = LETTERS_PER_LINE - name.length;
				var centeredName:String = "";
				for(var i:int = 0; i < spaces; i ++)
				{
					centeredName += " ";
				}
				centeredName +=  name;
				
				return centeredName;
			}
			return "";
		}
		
		override public function onLabelReached(label:String):void
		{
			shellApi.triggerEvent(label);
			switch( label )
			{
				case "cameraShow":
					cameraShowSound();
					break;
				case "cameraFocus":
					cameraFocusSound();
					break;
			}
		}
		
		override public function end():void
		{
			super.end();
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput( this, false );
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
		}
	}
}