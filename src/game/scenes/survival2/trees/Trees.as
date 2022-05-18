package game.scenes.survival2.trees
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Children;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.scene.SceneItemCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.profile.ProfileData;
	import game.data.sound.SoundModifier;
	import game.scene.template.ItemGroup;
	import game.scenes.custom.AdMiniBillboard;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival2.Survival2Events;
	import game.scenes.survival2.shared.Survival2Scene;
	import game.scenes.survival2.shared.flippingRocks.FlipGroup;
	import game.scenes.survival2.shared.flippingRocks.FlippableRock;
	import game.scenes.survival2.trees.Milipede.BodySegment;
	import game.scenes.survival2.trees.Milipede.BodySegmentSystem;
	import game.scenes.survival2.trees.SplatBug.SplatBugGroup;
	import game.scenes.survival2.trees.TweenPath.TweenPath;
	import game.scenes.survival2.trees.TweenPath.TweenPathSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.ItemHitSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class Trees extends Survival2Scene
	{
		public function Trees()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival2/trees/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private function setUpIslandData():void
		{
			if(shellApi.checkEvent(survival.FELL_AFTER_INTRO))
				return;
			
			// set default userfields to profile
			shellApi.setUserField("Trees_flip1", 3, shellApi.island);
			shellApi.setUserField("Trees_flip2", 3, shellApi.island);
			shellApi.setUserField("Trees_flip3", 3, shellApi.island);
			shellApi.setUserField("FishingHole_stone", 2, shellApi.island);
			shellApi.setUserField("BeaverDen_stone", 2, shellApi.island);
			shellApi.setUserField((super.events as Survival2Events).BAIT_FIELD, "none", shellApi.island);
			
			shellApi.profileManager.save();
		}
		
		private var survival:Survival2Events;
		
		private const HIDE_SOUND:String = "squish_08.mp3";
		private const RISE_SOUND:String = "squish_09.mp3";
		private const INSECT_SOUND:String = "small_insect_movement_01_loop.mp3";
		
		// all assets ready
		override public function loaded():void
		{
			survival = events as Survival2Events;
			super.loaded();
			
			addSystem(new HitTheDeckSystem());
			
			itemCreator = new SceneItemCreator();
			
			var itemHitSystem:ItemHitSystem = getSystem(ItemHitSystem) as ItemHitSystem;
			if(itemHitSystem == null)
			{
				itemHitSystem = new ItemHitSystem();
				addSystem(itemHitSystem);
			}
			itemHitSystem.gotItem.removeAll();
			itemHitSystem.gotItem.add(handleGotItem);
			
			setUpIslandData();
			setupBranches();
			setUpRocks();
			setUpGrafiti();
			setUpBugs();
			setUpPages();
			setUpMilipede();
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(2025, 490));	

			
			if(!shellApi.checkEvent(survival.FELL_AFTER_INTRO))
			{
				CharUtils.setState(player, CharacterState.HURT);
				SceneUtil.lockInput(this);
				SceneUtil.addTimedEvent(this, new TimedEvent(1, 1, getUp));
			}
		}
		
		private function getUp():void
		{			
			//probabbly going to comment about the situation
			SceneUtil.lockInput(this, false);
			CharUtils.setAnim(player, Stand);
			FSMControl(player.get(FSMControl)).active = true;
			shellApi.completeEvent(survival.FELL_AFTER_INTRO);
			var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			introPopup.updateText("you need to find something to eat. catch a fish to satisfy your hunger!", "start");
			introPopup.configData("popupIntro.swf", "scenes/survival2/trees/");
			addChildGroup(introPopup);
		}
		
		private function handleGotItem(item:Entity):void
		{
			var itemGroup:ItemGroup = super.getGroupById(ItemGroup.GROUP_ID, this) as ItemGroup;
			var itemID:String = item.get(Id).id;
			shellApi.completeEvent("got_"+itemID);
			if(itemID.indexOf("journal") != -1)
			{
				shellApi.getItem(survival.HAND_BOOK);
				itemGroup.showItem(survival.HAND_BOOK);
			}
			if(itemID.indexOf("page") != -1)
			{
				shellApi.getItem(survival.HAND_BOOK);
				itemGroup.showItem(survival.HAND_BOOK_PAGE);
			}
			if(itemID.indexOf("worm") != -1)
				itemGroup.showAndGetItem(survival.WORMS);
			if(itemID.indexOf("pillbug") != -1)
				itemGroup.showAndGetItem(survival.PILL_BUGS);
			if(itemID.indexOf("fishing_costume") != -1)
				itemGroup.showAndGetItem(survival.FISHING_COSTUME);
		}
		
		private var itemCreator:SceneItemCreator;
		
		private var lastEntity:Entity;
		private var head:Entity;
		private var start:Point = new Point(2300, 1355);
		private var startRun:Point = new Point(2645, 1352.5);
		
		private var moveSpeed:Number = 2;
		
		private var toCreatorPath:Vector.<Point>;
		private var runAwayPath:Vector.<Point>;
		
		private var path:int = 0;
		private var paths:Array;
		
		private var milipedeLayer:MovieClip;
		
		private function setUpMilipede():void
		{
			milipedeLayer = new MovieClip();
			milipedeLayer.mask = _hitContainer["milipedeMask"];
			EntityUtils.createSpatialEntity(this, milipedeLayer, _hitContainer);
			DisplayUtils.moveToOverUnder(milipedeLayer, _hitContainer["grafiti"]);
			var segments:int = 8;
			var segmentUrl:String = "scenes/survival2/trees/milipede/milipede.swf";
			//player.add(new BodySegment(null, 50));
			
			for(var i:int = 0; i < segments; i++)
			{
				shellApi.loadFile(shellApi.assetPrefix+segmentUrl, setUpSegment);
			}
			
			addSystem(new BodySegmentSystem());
			addSystem(new TweenPathSystem());
			addSystem(new HitTheDeckSystem());
			
			toCreatorPath = new Vector.<Point>();
			toCreatorPath.push(new Point(2425, 1390), new Point(2525, 1450), new Point(2675, 1380)
				, new Point(2725, 1300), new Point(2685, 1255), new Point(2630, 1275), new Point(2615, 1315)
				,startRun);
			
			runAwayPath = new Vector.<Point>();
			runAwayPath.push(new Point(2785, 1330), new Point(2850, 1425));
			
			paths = [toCreatorPath, runAwayPath];
		}
		
		private function setUpSegment(asset:DisplayObject):void
		{
			var clip:MovieClip = asset as MovieClip;
			if(PlatformUtils.isMobileOS)
				convertContainer(clip);
			clip.mouseEnabled = false;
			var segment:Entity = EntityUtils.createSpatialEntity(this, clip, milipedeLayer);
			TimelineUtils.convertAllClips(clip, segment, this, false);
			for each (var child:Entity in segment.get(Children).children)
			{
				TimelineUtils.moveTimelineToRandomFrame(child.get(Timeline), false);
			}
			var spatial:Spatial = segment.get(Spatial);
			if(lastEntity == null)
			{
				var range:AudioRange = new AudioRange(1000, 0, 1, Quad.easeIn);
				head = segment;
				segment.add(new BodySegment(null, 5,5, 25, -25, BodySegment.FOLLOW))
					.add(new TweenPath()).add(new HitTheDeck(player.get(Spatial),100,false))
					.add(new Audio()).add(range);
				spatial.x = start.x;
				spatial.y = start.y;
				TweenPath(segment.get(TweenPath)).reachedPoint.add(reachedPoint);
				HitTheDeck(segment.get(HitTheDeck)).duck.add(scareMilipede);
			}
			else
			{
				spatial.y = lastEntity.get(Spatial).y - 100;
				segment.add(new BodySegment(lastEntity.get(BodySegment), 5,5, 25, -25, BodySegment.FOLLOW));
			}
			lastEntity = segment;
			BodySegment(segment.get(BodySegment)).move.add(walk);
		}
		
		public function walk(milipede:Entity, walking:Boolean):void
		{
			var children:Children = milipede.get(Children);
			for each (var child:Entity in children.children)
			{
				Timeline(child.get(Timeline)).playing = walking;
			}
		}
		
		private function reachedPoint(milipede:Entity, end:Boolean):void
		{
			if(end)
			{
				Audio(milipede.get(Audio)).stop(SoundManager.EFFECTS_PATH+INSECT_SOUND,"effects");
				HitTheDeck(milipede.get(HitTheDeck)).ignoreProjectile = false;
				if(path == paths.length)
					removeEntity(milipede);
			}
		}
		
		private function scareMilipede(milipede:Entity):void
		{
			Audio(milipede.get(Audio)).play(SoundManager.EFFECTS_PATH+INSECT_SOUND, true, SoundModifier.POSITION);
			//SceneUtil.setCameraTarget(this, milipede);
			//SceneUtil.lockInput(this);
			HitTheDeck(milipede.get(HitTheDeck)).ignoreProjectile = true;
			TweenPath(milipede.get(TweenPath)).setPath(paths[path++], TweenPath.STOP, TweenPath.FACE,1/moveSpeed);
		}
		
		private function setUpPages():void
		{
			for(var i:int = 0; i <= 3; i++)
			{
				var clip:MovieClip;
				if(i == 0)
					clip = _hitContainer["journal"];
				else
					clip = hitContainer["page"+i];
				
				clip.mouseEnabled = false;
				clip.mouseChildren = false;
				
				var page:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				page.add(new Id(clip.name));
				itemCreator.make(page, new Point(25, 100));
				if(shellApi.checkEvent("got_"+clip.name))
					removeEntity(page);
			}
		}
		
		private var wormHeights:Point = new Point(955, 990);
		private var bugHeights:Point = new Point(1170, 1190);
		
		private const HEIGHT_RANGE:Number = 5;
		
		private function setUpBugs():void
		{
			var range:AudioRange = new AudioRange(350, 0, 1, Quad.easeIn);
			var bugs:Array = ["worm", "pillbug"];
			for(var bug:int = 0; bug < bugs.length; bug++)
			{
				var mask:MovieClip = _hitContainer[bugs[bug]+"Mask"];
				var bugLayer:MovieClip = new MovieClip();
				bugLayer.mask = mask;
				Display(EntityUtils.createSpatialEntity(this, bugLayer, _hitContainer).get(Display)).moveToBack();
				for(var i:int = 1; i <= 5; i++)
				{
					var clip:MovieClip = _hitContainer[bugs[bug]+i];
					if(clip == null)
						continue;
					
					if(PlatformUtils.isMobileOS)
						convertContainer(clip);
					
					var entity:Entity = EntityUtils.createSpatialEntity(this, clip, bugLayer);
					var duck:HitTheDeck = new HitTheDeck(player.get(Spatial), 100, false);
					TimelineUtils.convertClip(clip, this, entity);
					TimelineUtils.moveTimelineToRandomFrame(entity.get(Timeline));
					if(i == 1)//the weak bug that can be caught
					{
						duck.duckDistance = 50;
						duck.duck.add(Command.create(getBug, bug +1));
						entity.add(new SceneInteraction());
						InteractionCreator.addToEntity(entity, ["click"], clip);
						SceneInteraction(entity.get(SceneInteraction)).minTargetDelta = new Point(25, 50);
						ToolTipCreator.addToEntity(entity);
					}
					else
					{
						clip.mouseEnabled = false;
						duck.duck.add(Command.create(hide, bug));
						duck.coastClear.add(Command.create(rise, bug));
					}
					entity.add(duck).add(new Audio()).add(range);
					
					if(bug == 1)
						Audio(entity.get(Audio)).play(SoundManager.EFFECTS_PATH+INSECT_SOUND, true, SoundModifier.POSITION);
					
					if(i == 1)
					{
						if(shellApi.checkHasItem( bugs[bug]+"s"))
							removeEntity(entity);
					}
				}
			}
			
			addChildGroup(new SplatBugGroup(this, _hitContainer, 2));
		}
		
		private function rise(bug:Entity, bugType:int):void
		{
			var y:Number;
			if(bugType == 0)
				y = wormHeights.x;
			else
				y = bugHeights.x;
			
			y += Math.random() * HEIGHT_RANGE;
			
			Audio(bug.get(Audio)).play(SoundManager.EFFECTS_PATH + RISE_SOUND, false, SoundModifier.POSITION);
			
			TweenUtils.entityTo(bug, Spatial, 1, {y:y});
		}
		
		private function hide(bug:Entity, bugType:int):void
		{
			var y:Number;
			if(bugType == 0)
				y = wormHeights.y;
			else
				y = bugHeights.y;
			
			Audio(bug.get(Audio)).play(SoundManager.EFFECTS_PATH + HIDE_SOUND, false, SoundModifier.POSITION);
			
			TweenUtils.entityTo(bug, Spatial, 1, {y:y});
		}
		
		private function getBug(bug:Entity, rockNumber:int):void
		{
			var rock:Entity = getEntityById("flip"+rockNumber);
			if(FlippableRock(rock.get(FlippableRock)).currentPosition == 3)
				return;
			handleGotItem(bug);
			removeEntity(bug);
		}
		
		private var grafitiText:TextField;
		
		private const NEW_LINE:String = "\n";
		private var fullText:String = "";
		private var letter:int;
		
		private const LETTERS_PER_LINE:int = 13;
		
		private function setUpGrafiti():void
		{
			var clip:MovieClip = _hitContainer["grafiti"];
			var grafiti:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
			grafiti.add(new Id("grafiti"));
			
			var profile:ProfileData = shellApi.profileManager.active;
			
			grafitiText = clip["grafiti"];
			
			var format:TextFormat = grafitiText.defaultTextFormat;
			
			format.align =  TextFormatAlign.LEFT;
			
			grafitiText.defaultTextFormat = format;
			
			var words:Vector.<String> = new Vector.<String>();
			words.push(profile.avatarFirstName, profile.avatarLastName, "WAS", "HERE");
			
			for(var i:int = 0; i < words.length; i++)
			{
				fullText += String(createCenteredWord(words[i]) + NEW_LINE).toUpperCase();
			}
			
			if(shellApi.checkEvent( survival.ENGRAVED_NAME))
			{
				grafitiText.text = fullText;
				return;
			}
			
			grafitiText.text = "";
			
			ToolTipCreator.addToEntity(grafiti);
			
			InteractionCreator.addToEntity(grafiti, ["click"], clip);
			var interaction:SceneInteraction = new SceneInteraction();
			interaction.reached.add(encarveName);
			interaction.offsetY = 150;
			interaction.offsetX = 50;
			interaction.offsetDirection = true;
			interaction.autoSwitchOffsets = false;
			grafiti.add(interaction);
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
		
		private function encarveName(player:Entity, grafiti:Entity):void
		{
			SceneUtil.lockInput(this);
			letter = 0;
			SceneUtil.addTimedEvent(this, new TimedEvent(.25,fullText.length, engraveText));
		}
		
		private function engraveText():void
		{
			while(fullText.charAt(letter) == " ")
			{
				grafitiText.text += fullText.charAt(letter);
				++letter;
			}
			grafitiText.text += fullText.charAt(letter);
			letter ++;
			if(letter == fullText.length)
				engravedName();
		}
		
		private function engravedName():void
		{
			SceneUtil.lockInput(this, false);
			shellApi.completeEvent(survival.ENGRAVED_NAME);
			var grafiti:Entity = getEntityById("grafiti");
			grafiti.remove(SceneInteraction);
			grafiti.remove(Interaction);
			ToolTipCreator.removeFromEntity(grafiti);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "sparkle_01.mp3");
		}		
		
		private function setupBranches():void
		{
			var bounceEntity:Entity;
			var clip:MovieClip;
			var entity:Entity;
			var number:int;
			var timeline:Timeline;
			
			for( number = 1; number < 5; number ++ )
			{
				clip = _hitContainer[ "branch" + number ];
				if(PlatformUtils.isMobileOS)
					convertContainer(clip);
				bounceEntity = getEntityById( "bounce" + number );
				
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "branch" + number ));
				TimelineUtils.convertClip( clip, this, entity, null, false );
				
				bounceEntity.add( new TriggerHit( entity.get( Timeline )));
			}
		}
		
		private function setUpRocks():void
		{
			var flippingRocks:FlipGroup = addChildGroup(new FlipGroup(this, _hitContainer)) as FlipGroup;
			
			for(var i:int = 1; i <= 3; i++)
			{
				var clip:MovieClip = _hitContainer["flip"+i];
				if(PlatformUtils.isMobileOS)
					convertContainer(clip);
				var rock:Entity = flippingRocks.createFlippingEntity(clip, "flipstone",5,3,true,4-i);
				FlippableRock(rock.get(FlippableRock)).flipped.add(Command.create(flippedRock, rock, i));
			}
		}
		
		private function flippedRock(rock:Entity, rockNumber:int):void
		{
			var flip:FlippableRock = rock.get(FlippableRock);
			var bug:Entity;
			if(rockNumber == 1)
				bug = getEntityById("worm1");
			else if(rockNumber == 2)
				bug = getEntityById("pillbug1");
			
			if(bug == null)
				return;
			
			if(flip.currentPosition == 3)
				ToolTipCreator.removeFromEntity(bug);
			else
			{
				var distance:Number = Point.distance(EntityUtils.getPosition(bug), EntityUtils.getPosition(player));
				if(distance <= 50)
					getBug(bug, rockNumber);
				else if(Children(bug.get(Children)).children.length == 0)
					ToolTipCreator.addToEntity(bug);
			}
		}
	}
}