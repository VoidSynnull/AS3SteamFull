package game.scenes.backlot.mainStreet
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.entity.character.Skin;
	import game.components.entity.character.part.SkinPart;
	import game.components.scene.SceneInteraction;
	import game.components.hit.Hazard;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Salute;
	import game.data.game.GameEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.data.sound.SoundModifier;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class MainStreet extends PlatformerGameScene
	{
		public function MainStreet()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/mainStreet/";
			
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
			_events = super.events as BacklotEvents;
			super.loaded();
			super.shellApi.eventTriggered.add( onEventTriggered );
			
			setUpTraffic();
			setUpCar();
			setUpPages();
			setupPaparazzi();
		}
		
		private function setUpTraffic():void
		{
			var lights:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["lights"],_hitContainer);
			TimelineUtils.convertClip(this._hitContainer["lights"],this,lights);
			_trafficLights = lights.get(Timeline);
			_trafficLights.labelReached.add(trafficPattern);
			var audioRange:AudioRange = new AudioRange(600, .01, 3);
			lights.add(new Audio()).add(audioRange).add(new Id("lights"));
		}
		
		private function trafficPattern(label:String):void
		{
			if(label == "lightChange")
			{
				var lights:Entity = getEntityById("lights");
				Audio(lights.get(Audio)).play("effects/ping_10.mp3");
			}
			if(label == "startCar1" || label == "startCar2")
			{
				_carPath.gotoAndPlay("go");
			}
		}
		
		private function setUpCar():void
		{
			_carHit = super.getEntityById("carHit");
			_carHazard = _carHit.get(Hazard);
			_carHit.remove(Hazard);
			
			Display(_carHit.get(Display)).alpha = 0;
			
			var carClip:MovieClip = _hitContainer["vehicle"];
			
			var car:Entity = EntityUtils.createSpatialEntity(this, carClip, _hitContainer);
			car.add(new Id("car"));
			TimelineUtils.convertClip(this._hitContainer["vehicle"],this, car);
			
			car.remove(Sleep);
			
			_carPath = car.get(Timeline);
			_carPath.gotoAndStop(0);
			_carPath.labelReached.add(driveBy);
		}
		
		private function driveBy( label:String ):void
		{
			var carDisplay:Display = super.getEntityById("car").get(Display);
			if(label == "go")
				MovieClip(carDisplay.displayObject).car.gotoAndStop(int(Math.random() * 5) + 1);
			if(label == "ending")
			{
				_carPath.stop();
				carDisplay.moveToFront();
			}
			if(label == "inRoad")
			{
				if(_carHit.get(Hazard) == null)
					_carHit.add(_carHazard);
				//trace("players X: " + super.player.get(Spatial).x + " hitX: " + _carHit.get(Spatial).x);
				if(super.player.get(Spatial).x > _carHit.get(Spatial).x + _carHit.get(Spatial).width / 2)
					_carHazard.velocity.x = Math.abs(_carHazard.velocity.x);
				else
					_carHazard.velocity.x = -Math.abs(_carHazard.velocity.x);
				//trace(_carHazard.velocity.x);
			}
			if(label == "pass")
			{
				_carHit.remove(Hazard);
				carDisplay.moveToBack();
			}
		}		
		
		private function setUpPages():void
		{
			for(var i : int = 3; i < 5; i ++)
			{
				var pageName:String = "page" + i;
				var page:Entity = EntityUtils.createSpatialEntity(this,this._hitContainer[pageName],this._hitContainer);
				TimelineUtils.convertClip(this._hitContainer[pageName],this,page);
				var eventName:String = "got_page_" + i;
				if(super.shellApi.checkEvent(_events.PAGES_BLEW_AWAY))
				{
					if(super.shellApi.checkEvent(eventName))
						super.removeEntity(page);// may need to make it invisible
					else
					{
						page.add(new Id(eventName));
						page.add(new SceneInteraction());
						var interaction:Interaction = InteractionCreator.addToEntity(page,[InteractionCreator.CLICK],this._hitContainer[pageName]);
						ToolTipCreator.addToEntity(page);
						var pageInteraction:SceneInteraction = page.get(SceneInteraction);
						pageInteraction.reached.add(collectPage);
						var audioRange:AudioRange = new AudioRange(1000, .01, 1, Quad.easeIn);
						page.add(new Audio()).add(audioRange);
						Audio(page.get(Audio)).play("effects/paper_flap_01.mp3",true, SoundModifier.POSITION);
					}
				}
				else
				{
					super.removeEntity(page);
				}
			}
		}
		
		private function collectPage(player:Entity, page:Entity):void
		{
			super.shellApi.triggerEvent(page.get(Id).id, true);
			super.shellApi.getItem(_events.SCREENPLAY_PAGES,null,true);
			super.removeEntity(page);
		}
		
		private function setupPaparazzi():void
		{
			if(!super.shellApi.checkEvent( _events.ARRIVE_AT_BACKLOT))
			{
				SceneUtil.lockInput(this, true, false);
				CharUtils.lockControls( super.player, true, true );
				CharUtils.moveToTarget( super.player, 3050, 1192, false, openingSequence );
			}
			else
				removePaparazzi();
		}
		
		private function removePaparazzi():void
		{
			super.removeEntity(super.getEntityById( "char1" ));
			super.removeEntity(super.getEntityById( "char2" ));
			super.removeEntity(super.getEntityById( "char3" ));
		}
		
		private function openingSequence( entity:Entity = null ):void 
		{
			CharUtils.moveToTarget( super.getEntityById( "char1" ), 3150, 1192, false, lookAStar );
			CharUtils.moveToTarget( super.getEntityById( "char2" ), 3250, 1192, false );
			CharUtils.moveToTarget( super.getEntityById( "char3" ), 3350, 1192, false );
		}
		
		private function lookAStar( entity:Entity = null ):void
		{
			Dialog( super.getEntityById( "char1" ).get(Dialog)).sayById("celeb");
		}
		
		private function takePictures():void
		{
			var take3Pics:Vector.<Class> = new Vector.<Class>();
			take3Pics.push(Salute, Salute, Salute);
			CharUtils.setAnimSequence(super.getEntityById( "char1" ), take3Pics);
			CharUtils.setAnimSequence(super.getEntityById( "char3" ), take3Pics);
			
			Timeline(getEntityById( "char1" ).get(Timeline)).handleLabel("raised",takePic,false);
		}
		
		private function takePic():void
		{
			shellApi.triggerEvent(_events.PHOTO_SHOOT);
			
			flashTheCamera(1);
			flashTheCamera(3);
			
			_picturesTook++;
			if(_picturesTook == 3)
				SceneUtil.addTimedEvent(this, new TimedEvent(1,1,finishBarage));
		}
		
		private function flashTheCamera(charNumber:int):void
		{
			var cameraEnt:Entity = SkinUtils.getSkinPartEntity(getEntityById( "char"+charNumber ),SkinUtils.ITEM);
			
			var camera:MovieClip = Display(cameraEnt.get(Display)).displayObject as MovieClip;
			
			camera = camera.getChildAt(0) as MovieClip;
			
			var cameraFlash:MovieClip = camera.cameraFlash;
			
			var flashEnt:Entity = EntityUtils.createSpatialEntity(this, cameraFlash, camera);			
			
			SceneUtil.addTimedEvent(this, new TimedEvent(.01,10,Command.create(dimFlash, flashEnt)));
		}
		
		private function dimFlash(camFlash:Entity):void
		{
			Display(camFlash.get(Display)).alpha -=.1;
		}
		
		private function finishBarage():void
		{
			//trace("continue dialog");
			Dialog( super.getEntityById( "char3" ).get(Dialog)).sayById("nvm");
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			//trace(event);
			if( event ==_events.YOUR_NOT_FAMOUS )
			{
				takePictures();
			}
			if( event ==_events.LOOK_OVER_THERE )
			{
				CharUtils.moveToTarget( super.getEntityById( "char2" ), 3300, 1192 );
			}
			if( event ==_events.MOVE_OVER_THERE )
			{
				moveOverThere();
			}
			
			var playerDialog:Dialog = player.get(Dialog);
			
			if( event == _events.CAMERA)
			{
				if(player.get(Spatial).x > super.getEntityById("photographer").get(Spatial).x + shellApi.camera.camera.viewportWidth)
					playerDialog.sayById("need to fix");
				else
				{
					super.getEntityById("photographer").get(Dialog).sayById("nice camera");
					SceneUtil.lockInput(this);
				}
			}
			
			if( event == GameEvent.GOT_ITEM + _events.FILM)
			{
				SceneUtil.lockInput(this, false);
			}
			
			if( event == _events.CAMERA_AND_FILM)
			{
				playerDialog.sayById("not now");
			}
		}
		
		private function moveOverThere():void
		{
			var char2:Entity = getEntityById("char2");
			FSMControl(char2.get(FSMControl)).active = true;
			// I don't know why char2's FSMCOntrol decides to go inactive but I had to reactivate it
			//(was the reason he wasn't running with the others) I dont know what changed because it worked fine originally
			
			for(var i:int = 1; i <= 3; i++)
			{
				var char:Entity = getEntityById("char"+i);
				if(i == 1)
					CharUtils.moveToTarget(char, 4000, 1192, false, seeYa);
				else
					CharUtils.moveToTarget(char, 4000, 1192);
				//trace("everyone runs");
			}
		}
		
		private function seeYa( entity:Entity = null) : void
		{
			removePaparazzi();
			SceneUtil.lockInput(this, false, false);
			CharUtils.lockControls( super.player, false, false );
			super.shellApi.triggerEvent( _events.ARRIVE_AT_BACKLOT, true );
		}
		
		private var _carHazard:Hazard;
		private var _trafficLights:Timeline;
		private var _carHit:Entity;
		private var _carPath:Timeline;
		private var _events:BacklotEvents;
		private var _picturesTook:int = 0;
	}
}