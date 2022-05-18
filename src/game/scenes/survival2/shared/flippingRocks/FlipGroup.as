package game.scenes.survival2.shared.flippingRocks
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialOffset;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Children;
	import game.components.hit.Platform;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.FlipObject;
	import game.data.sound.SoundModifier;
	import game.components.entity.FollowClipInTimeline;
	import game.systems.entity.FollowClipInTimelineSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class FlipGroup extends Group
	{
		private var scene:Group;
		private var container:DisplayObjectContainer;
		
		private const LIFT_SOUND:String = "lift_heavy_object_from_dirt_01.mp3";
		private const LAND_SOUND:String = "snow_large_impact_01.mp3";
		
		private var audioRange:AudioRange;
		
		public function FlipGroup(scene:Group, container:DisplayObjectContainer)
		{
			this.scene = scene;
			this.container = container;
			this.scene.addSystem(new FollowClipInTimelineSystem());
			audioRange = new AudioRange(500, 0,1);
		}
		
		public function createFlippingEntity(clip:MovieClip, objectName:String, flips:int, startPosition:int, makePlatforms:Boolean = true, assetFrame:int = 1, top:Boolean = false):Entity
		{
			if(PlatformUtils.isMobileOS) BitmapUtils.convertContainer(clip);
			
			MovieClip(clip[objectName]).gotoAndStop(assetFrame);
			
			var rock:Entity = EntityUtils.createSpatialEntity(scene, clip, container);
			TimelineUtils.convertClip(clip, scene, rock, null, false);
			rock.add(new FlippableRock(rock.get(Timeline), flips, startPosition, 0, top)).add(new SceneInteraction()).add(new Id(clip.name)).add(new Audio()).add(audioRange);
			var interact:Interaction = InteractionCreator.addToEntity(rock, ["click"], clip);
			interact.click.add(clickRock);
			var interaction:SceneInteraction = rock.get(SceneInteraction);
			interaction.minTargetDelta.x = 50;
			interaction.minTargetDelta.y = 150;
			interaction.autoSwitchOffsets = false;
			interaction.offsetDirection = true;
			interaction.validCharStates = new <String>[CharacterState.STAND];
			interaction.reached.add(Command.create(flipRock));
			ToolTipCreator.addToEntity(rock);
			
			var flip:FlippableRock = rock.get(FlippableRock);
			flip.objectName = objectName;
			
			flip.flipped.add(Command.create(flipped, rock));
			
			var extraPlatformLength:Number = 25;
			
			if(makePlatforms)
			{
				var object:MovieClip = clip[flip.objectName];
				
				var bounds:Rectangle = object.getBounds(object);
				
				var offsetHeight:Number = 0;
				
				if(top)
				{
					offsetHeight = -bounds.height / 2;
					extraPlatformLength = 0;
				}
				
				var platClip:Sprite = new Sprite();
				platClip.mouseEnabled = false;
				
				platClip.graphics.beginFill(0,0);
				platClip.graphics.drawRect(bounds.x - extraPlatformLength, bounds.y, bounds.width + extraPlatformLength * 2, bounds.height);
				platClip.mouseEnabled = false;
				
				var rockPlatform:Entity = EntityUtils.createSpatialEntity(scene, platClip, container);
				rockPlatform.add(new Platform()).add(new FollowClipInTimeline(object,new Point(0, offsetHeight),rock.get(Spatial), true)).add(new Id(clip.name + "_platform"));
				DisplayUtils.moveToOverUnder(platClip, clip,false);
				
				if(top)
				{
					platClip = new Sprite();
					platClip.mouseEnabled = false;
					platClip.graphics.beginFill(0,0);
					platClip.graphics.drawRect(bounds.x - extraPlatformLength, bounds.y, bounds.width + extraPlatformLength * 2, bounds.height);
					platClip.mouseEnabled;
					
					rockPlatform = EntityUtils.createSpatialEntity(scene, platClip, container);
					rockPlatform.add(new Platform()).add(new FollowClipInTimeline(object,new Point(0, offsetHeight),rock.get(Spatial), true, 180)).add(new Id(clip.name + "_platform2"));
					DisplayUtils.moveToOverUnder(platClip, clip,false);
				}
			}
			
			//some time before 11/14 : was decided not necessary to save to server, just for the current play through, but if it was, make the false true || shellApi.networkAvailable()
			//on 11/14 : new users who have userfield data, but no userfields for them on the server, caused issues, because the server didn't know which user fields were to be saved or not so just assumed all user fields were to be saved
			// working on a solution so menial things like these don't have to be saved to server, but in the mean time we will just have to
			shellApi.getUserField(shellApi.sceneName+"_"+clip.name,shellApi.island,Command.create(gotRockPosition, startPosition, rock));
			return rock;
		}
		
		private function gotRockPosition(currentPosition:*, startPosition:int, rock:Entity):void
		{
			var position:uint;
			if ( !DataUtils.isNull( currentPosition ))
				position = DataUtils.getUint(currentPosition);
			else
				position = startPosition;
			
			var flippableRock:FlippableRock = rock.get(FlippableRock);
			flippableRock.currentPosition = position;
			Timeline(rock.get(Timeline)).gotoAndStop(flippableRock.POSITION+position);
			flipped(rock);
		}
		
		private function clickRock(rock:Entity):void// making it so the offset is to more one side or the other of the rock
		{
			var playerSpatial:Spatial = scene.shellApi.player.get(Spatial);
			var rockSpatial:Spatial = rock.get(Spatial);
			var interaction:SceneInteraction = rock.get(SceneInteraction);
			
			var flip:FlippableRock = rock.get(FlippableRock);
			var clip:MovieClip = Display(rock.get(Display)).displayObject as MovieClip;
			var rockClip:MovieClip = clip[flip.objectName];
			
			if(playerSpatial.x < (rockSpatial.x + rockClip.x))
			{
				flip.flippingForward = true;
				if(flip.canFlip())
				{
					interaction.offsetX = rockClip.x - rockClip.width / 4;
				}
			}
			else
			{
				flip.flippingForward = false;
				if(flip.canFlip())
				{
					interaction.offsetX = rockClip.x + rockClip.width / 4;
				}
			}
		}
		
		private function flipped(rock:Entity):void
		{
			FSMControl(scene.shellApi.player.get(FSMControl)).active = true;
			var interaction:SceneInteraction = rock.get(SceneInteraction);
			var clip:MovieClip = Display(rock.get(Display)).displayObject as MovieClip;
			
			var flip:FlippableRock = rock.get(FlippableRock);
			var rockClip:MovieClip = clip[flip.objectName];
			interaction.offsetX = rockClip.x;
			interaction.offsetY = rockClip.y;
			
			var platform:Entity = scene.getEntityById(rock.get(Id).id+"_platform");
			if(platform != null)
			{
				platform.add(new Platform());
				if(flip.top)
				{
					platform = scene.getEntityById(rock.get(Id).id+"_platform2");
					platform.add(new Platform());
				}
			}
			
			var toolTip:Entity = Children(rock.get(Children)).children[0];
			var offSet:SpatialOffset = toolTip.get(SpatialOffset);
			offSet.x = interaction.offsetX;
			offSet.y = interaction.offsetY;
			
			var saveDestination:String = scene.shellApi.sceneName+"_"+rock.get(Id).id;
			
			// NOTE :: Don't think we really need to save this to the backend. -bard
			shellApi.setUserField(saveDestination, flip.currentPosition, shellApi.island);
			
			Audio(rock.get(Audio)).play(SoundManager.EFFECTS_PATH + LAND_SOUND, false,SoundModifier.POSITION);
			
			SceneUtil.lockInput(this, false);
		}
		
		private function flipRock(player:Entity, rock:Entity):void
		{
			SceneUtil.lockInput(this);
			var flipRock:FlippableRock = rock.get(FlippableRock);
			CharUtils.setAnim(player, FlipObject);
			if(!flipRock.canFlip())
			{
				SceneUtil.lockInput(this, false);
				return;
			}
			Timeline(player.get(Timeline)).handleLabel("flip", Command.create(flip, player, rock));
			var platform:Entity = scene.getEntityById(rock.get(Id).id+"_platform");
			if(platform != null)
			{
				platform.remove(Platform);
				if(flipRock.top)
				{
					platform = scene.getEntityById(rock.get(Id).id+"_platform2");
					platform.remove(Platform);
				}
			}
			Audio(rock.get(Audio)).play(SoundManager.EFFECTS_PATH + LIFT_SOUND, false,SoundModifier.POSITION);
			
			CharUtils.setDirection(player, flipRock.flippingForward);
		}
		
		private function flip(player:Entity, rock:Entity):void
		{
			var flipRock:FlippableRock = rock.get(FlippableRock);
			flipRock.flip(flipRock.flippingForward);
		}
	}
}