package game.scenes.carrot.engine
{
	import com.greensock.TweenLite;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.motion.FollowTarget;
	import game.components.entity.Sleep;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.scenes.carrot.CarrotEvents;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.util.DisplayUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	
	public class Engine extends PlatformerGameScene
	{
		public function Engine()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/engine/";
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

			_events = super.events as CarrotEvents; 
			_crane = super.getEntityById("crane");
			_craneL = super.getEntityById("craneL");
			Display( _craneL.get( Display )).alpha = 0;
			
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToEntity( _crane );
			if(! super.shellApi.checkEvent( _events.ENGINE_ON ))
			{
				Spatial(_crane.get(Spatial)).x += 1000;
				Spatial(_craneL.get(Spatial)).x += 1000;
				
				Sleep(_crane.get(Sleep)).ignoreOffscreenSleep = true;
				Sleep(_craneL.get(Sleep)).ignoreOffscreenSleep = true;
				Sleep(_crane.get(Sleep)).sleeping = true;
				Sleep(_craneL.get(Sleep)).sleeping = true;
				
				super._hitContainer["animation1"]["glow"].visible = false;
				super._hitContainer["animation2"]["glow"].visible = false;
				super._hitContainer["animation3"]["glow"].visible = false;
				
				_screenEffects = new ScreenEffects();
				
				_lights = _screenEffects.createBox(super.shellApi.viewportWidth, super.shellApi.viewportHeight, 0x000000);
				_lights.alpha = .4;
				_lights.mouseEnabled = false;
				_lights.x = -super.shellApi.viewportWidth * .5;
				_lights.y = -super.shellApi.viewportHeight * .5;
				super.groupContainer.addChild(_lights);
			}
			else
			{
				// to re-set music if the engine is already on
				super.shellApi.triggerEvent( _events.ENGINE_ON );
				super._hitContainer["interaction1"]["ball"].y = 25;
				super._hitContainer["interaction2"]["ball"].y = 50;
				super._hitContainer["interaction3"]["ball"].y = 25;
				beginSparks();
				spinGears(super._hitContainer, true);
			}
			
			SceneInteraction(super.getEntityById("interaction1").get(SceneInteraction)).reached.add(sceneInteractionTriggered);
			SceneInteraction(super.getEntityById("interaction2").get(SceneInteraction)).reached.add(sceneInteractionTriggered);
			SceneInteraction(super.getEntityById("interaction3").get(SceneInteraction)).reached.add(sceneInteractionTriggered);
		}
				
		private function sceneInteractionTriggered(character:Entity, interaction:Entity):void
		{
			if(! super.shellApi.checkEvent( _events.ENGINE_ON ))
			{
				var interactionId:String = interaction.get(Id).id;
				var interactionDisplay:DisplayObject = Display(interaction.get(Display)).displayObject;
				var ball:MovieClip = MovieClip(interactionDisplay).ball;
				var targetY:Number = 0;
				var index:int = int(interactionId.slice(String("interaction").length)) - 1;
								
				if(ball.y == 0)
				{
					targetY = 25;
				}
				else if(ball.y == 25)
				{
					targetY = 50;
				}
				else
				{
					targetY = 0;
				}
				
				TweenLite.to(ball, .2, { y : targetY });
				
				_currentPositions[index] = targetY;

				if(_currentPositions[index] == _targetPositions[index])
				{
					super.shellApi.triggerEvent( _events.LEVER_CORRECT );
					super._hitContainer["animation" + (index + 1)]["glow"].visible = true;
				}
				else
				{
					super.shellApi.triggerEvent( _events.LEVER_MOVE );
					super._hitContainer["animation" + (index + 1)]["glow"].visible = false;
				}
				
				if(_currentPositions.toString() == _targetPositions.toString())
				{
					Sleep(_crane.get(Sleep)).sleeping = false;
					Sleep(_craneL.get(Sleep)).sleeping = false;
					TweenLite.to(_lights, 1, { alpha : 0 });
					super.shellApi.triggerEvent( _events.ENGINE_ON, true);
					beginSparks();
					spinGears(super._hitContainer);
				}
			}
		}		
				
		private function beginSparks():void
		{
			var sparks:Sparks = new Sparks();
			
			sparks.init();
			
			var entity:Entity = EmitterCreator.create(this, super._hitContainer, sparks, 0, -350, null, "sparks", _crane.get(Spatial));			
			var sleep:Sleep = new Sleep();
			sleep.zone = super.sceneData.bounds;
			entity.add(sleep);
			SceneUtil.addTimedEvent( this, new TimedEvent( Math.random() * 5, 1, sparkSound ));
		}
		
		private function sparkSound():void
		{
			super.shellApi.triggerEvent( _events.SHOOT_SPARKS );	
			SceneUtil.addTimedEvent( this, new TimedEvent( Math.random() * 5, 1, sparkSound ));
		}
		
		private function spinGears(container:DisplayObjectContainer, alreadyRunning:Boolean = false):void
		{			
			var total:Number = container.numChildren;
			var clip:DisplayObjectContainer;
			var axel:Entity;
			var motion:Motion;
			
			for (var n:Number = total - 1; n >= 0; n--)
			{
				clip = container.getChildAt(n) as DisplayObjectContainer;
				
				if (clip != null)
				{
					if(clip.name.indexOf("axel") > -1)
					{
						motion = new Motion();
						
						if(alreadyRunning)
						{
							motion.rotationVelocity = 200;
						}
						else
						{
							motion.rotationAcceleration = 10;
							motion.rotationMaxVelocity = 200;
						}
						
						axel = new Entity();
						axel.add(motion);
						axel.add(new Spatial());
						axel.add(new Sleep());
						axel.add(new Display(clip));
						convertContainer(clip);
						super.addEntity(axel);
					}
				}
			}
		}
		
		private var _crane:Entity;
		private var _craneL:Entity;
		private var _events:CarrotEvents;
		private var _switchPositions:Array = [0, 25, 50];
		private var _currentPositions:Array = [0, 0, 0];
		private var _targetPositions:Array = [25, 50, 25];
		private var _lights:Sprite;
		private var _screenEffects:ScreenEffects;
	}
}