package game.scenes.custom
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Player;
	import game.components.hit.CurrentHit;
	import game.components.hit.EntityIdList;
	import game.components.hit.HitTest;
	import game.components.hit.MovieClipHit;
	import game.components.motion.FollowTarget;
	import game.components.timeline.Timeline;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.StandNinja;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.managers.ads.AdManager;
	import game.scene.template.CharacterGroup;
	import game.scenes.custom.LoopingPopupSystems.LoopingSegments;
	import game.systems.hit.HitTestSystem;
	import game.systems.hit.MovieClipHitSystem;
	import game.systems.motion.FollowTargetSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class FlyGame extends AdGamePopup
	{
		public var _scale:Number = NaN;
		private var segments:LoopingSegments;
		private var char:Entity;
		private var charGroup:CharacterGroup;
		private var content:MovieClip;
		private var lives:int;
		private var life:int = 0;
		private var hud:Timeline;
		private var animations:Dictionary;
		private var hitSounds:Dictionary;
		private var hitFeedBack:Entity;
		private static const IDLE:String = "idle";
		private static const HURT:String = "hurt";
		private var _customPlayer:Boolean = false;   	 //custom animated player
		private var _customPlayerClip:MovieClip;			//custom animated player
		private var _customPlayerEnt:Entity;
		
		public function FlyGame()
		{
			super();
		}
		
		override protected virtual function parseXML(xml:XML):void
		{
			super.parseXML(xml);
			// making sure there is always a fall back for hurt and idle animations
			animations = new Dictionary();
			animations[IDLE] = StandNinja;
			animations[HURT] = Hurt;
			if(xml.hasOwnProperty("animations"))
			{
				setUpStates(xml.animations);
			}
			if(xml.hasOwnProperty("sounds"))
			{
				setUpHitSounds(xml.sounds);
			}
			
		}
		
		private function setUpHitSounds(xml:XMLList):void
		{
			hitSounds = new Dictionary();
			for(var i:int = 0; i < xml.children().length(); i++)
			{
				var sound:XML = xml.children()[i];
				var hitId:String = DataUtils.getString(sound.attribute("id")[0]);
				if(hitId != null)
					hitSounds[hitId] = DataUtils.getString(sound);
			}
		}
		
		private function setUpStates(xml:XMLList):void
		{
			// unique animations should have the naming convention skin-id + idle or skin-id + hurt
			// skin ids refer to the looks for each skin in the fly.xml for character select
			// example for <skin id="antman"> the idle id was <animation id="antmanidle">
			// the class path should be written out following the folder paths seperated with periods
			// <animation id="antmanidle">game.data.animation.entity.character.Stand</animation>
			for(var i:int = 0; i < xml.children().length(); i++)
			{
				var state:XML = xml.children()[i];
				var stateClass:Class = ClassUtils.getClassByName(DataUtils.getString(state));
				var animId:String = DataUtils.getString(state.attribute("id")[0]);
				if(stateClass == null || animId == null)
				{
					trace(state+" class path or id is invalid");
					continue;
				}
				animations[animId] = stateClass;
			}
		}
		
		override protected virtual function playerSelection(selection:int = -1):void
		{
			_selection = selection;
			trace("selection: " + _selection);
			if(selection > 0 && selection < _looks.length + 1)
			{
				trace("selection valid " + char);
				var look:LookData = _looks[selection-1];
				if(!_customPlayer)
				{
					SkinUtils.applyLook(char, look,false,playerSelected);
					Id(char.get(Id)).id = look.id;
				}
				else
					playerSelected();
			}
			else
			{
				trace("selection not valid");
				playerSelected();
			}
		}
		
		override protected virtual function playerSelected(...args):Boolean
		{
			if(super.playerSelected())
			{
				trace("selection made and will now start game");
				var selectionClip:MovieClip = content["selection"];
				if(selectionClip != null)
				{
					selectionClip.gotoAndStop(_selection);
				}
				segments.motionMaster.active = true;
				setAnimation(IDLE);// start the game in the correct idle animation
				finalizeGame();
				return true;
			}
			trace("selection not made");
			return false;
		}
		
		override protected virtual function loadedSwf(clip:MovieClip):void
		{
			// save clip to screen
			super.screen = clip;
			autoOpen = false;
			super.preparePopup();
			super.centerPopupToDevice();
			setupAvatar();
			
			// play music
			if (_musicFile != null)
			{
				AdManager(super.shellApi.adManager).playCampaignMusic(_musicFile);
			}
		}
		
		private function setupAvatar():void
		{
			trace("setup avatar");
			// top left corner
			content = screen.content;
			content.x -= shellApi.viewportWidth/2;
			content.y -= shellApi.viewportHeight/2;
			
			charGroup = this.getGroupById("characterGroup") as CharacterGroup;
			if(!charGroup)
			{
				charGroup = new CharacterGroup();
				charGroup.setupGroup(this, content );
			}
			var clip:MovieClip = content["player"];
			var lookData:LookData;
			if (clip)
			{
				_customPlayerClip = clip;
				lookData = new LookData();
				// list of parts except head, body, eyes, mouth, and limbs
				var partsList:Array = [SkinUtils.FACIAL, SkinUtils.MARKS, SkinUtils.HAIR, SkinUtils.SHIRT, SkinUtils.PANTS, SkinUtils.PACK, SkinUtils.ITEM, 
					SkinUtils.OVERPANTS, SkinUtils.OVERSHIRT];
				for each (var part:String in partsList)
				{
					var lookAspect:LookAspectData = new LookAspectData( part, "empty" );
					lookData.applyAspect(lookAspect);
				}
				_customPlayer = true;
			}
			else
			{
				lookData = SkinUtils.getLook(shellApi.player);
				lookData.fillWithEmpty();// make sure parts dont get left in the dust
			
			}
			charGroup.createDummy("char", lookData,"right","",content,this,initializeGame,false, _scale);
		}

		private function initializeGame(entity:Entity):void
		{
			char = entity;
			trace("got char " + char);
			
			segments = addChildGroup(new LoopingSegments(content)) as LoopingSegments;
			var gameName:String = _swfName.substring(1, _swfName.indexOf(".swf"));
			var motionUrl:String = xmlPath.replace(gameName, "motionMaster");
			var segmentsUrl:String = xmlPath.replace(gameName, "segmentPatterns");
			segments.initData(groupPrefix+motionUrl, groupPrefix+segmentsUrl);
			segments.ready.addOnce(SetUpGame);
			segments.reachedEnd.addOnce(Command.create(endGame, true));
		}
		private function PlayIdle():void
		{
			_customPlayerEnt.get(Timeline).gotoAndPlay("idle");
		}
		private function SetUpGame(...args):void
		{
			trace("set up game " + char);
			// progress bar
			var clip:MovieClip = content["progress"];
			if (clip)
			{
				var child:MovieClip = clip["progress"];
				var mask:MovieClip = clip["mask"];
				if(child && mask)
				{
					child.mask = mask;
					clip = mask;
				}
				segments.motionMaster.progressDisplay = clip;
				segments.motionMaster.progressLength = segments.motionMaster.axis == "x"? clip.width:clip.height;
			}
			var text:TextField = content["progressText"];
			if (text)
			{
				segments.motionMaster.progressDisplayText = text;
			}
			//lives bar
			clip = content["hud"];
			if(clip)
			{
				var entity:Entity = TimelineUtils.convertClip(clip, this,entity, null, false);
				lives = clip.totalFrames -1;
				hud = entity.get(Timeline);
			}
			
			clip = content["hitFeedBack"];
			if(clip)
			{
				hitFeedBack = EntityUtils.createSpatialEntity(this, clip);
				TimelineUtils.convertClip(clip, this, hitFeedBack, null, false);
				Sleep(hitFeedBack.get(Sleep)).ignoreOffscreenSleep = true;
			}
			// movement
			var inputSpatial:Spatial = parent.shellApi.inputEntity.get(Spatial);
			var followTarget:FollowTarget = new FollowTarget( inputSpatial, .05 );
			followTarget.properties = new <String>[segments.motionMaster.axis == "x"?"y":"x"];
			char.add(followTarget).add(segments.motionMaster).add(new Player());
			if(_customPlayer)
			{
				_customPlayerEnt = TimelineUtils.convertClip(_customPlayerClip, this,_customPlayerEnt, null, false);
				
				char.add(new Display(_customPlayerClip));
				
			}
			
			char.get(Sleep).ignoreOffscreenSleep = true;
			
			// create the collider for the player, making sure that its the same
			// no matter what ridiculous costume they may be wearing... antman cough cough
			clip = new MovieClip();
			clip.graphics.beginFill(0,0);
			clip.graphics.drawCircle(0,-10,35);
			clip.graphics.endFill();
			var hit:Entity = EntityUtils.createSpatialEntity(this, clip, content);
			
			// adding necesary systems
			if(getSystem(FollowTargetSystem) == null)
				addSystem(new FollowTargetSystem());
			if(getSystem(HitTestSystem) == null)
				addSystem(new HitTestSystem());
			if(getSystem(MovieClipHitSystem) == null)
				addSystem(new MovieClipHitSystem());
			
			var spatial:Spatial = char.get(Spatial);
			var clipHit:MovieClipHit = new MovieClipHit();
			//clipHit.shapeHit = true;
			hit.add(new FollowTarget(spatial)).add(clipHit).add(new CurrentHit())
				.add(new HitTest(onHit)).add(new EntityIdList());
			
			if(segments.motionMaster.axis == "x")
			{
				spatial.x = 100;
				spatial.y = inputSpatial.y;
			}
			else if(segments.motionMaster.axis == "y" && segments.motionMaster.direction == "-")
			{
				spatial.y = 100;
				spatial.x = inputSpatial.x;
			}
			else
			{
				spatial.y = shellApi.viewportHeight - 100;
				spatial.x = inputSpatial.x;
			}
			segments.initSegments();
			
			// if there are selections to be made start that
			if(_looks != null)
			{
				var selectionPopup:AdChoosePopup = loadGamePopup("AdChoosePopup",null) as AdChoosePopup;
				selectionPopup.selectionMade.addOnce(playerSelection);
				// waiting for popup to be removed so we are not removing a popup that is about to remove itself
			}
			else
			{
				//  get the game started
				playerSelected();
			}
		}
		private function PlayerHandler( label:String ):void
		{
			if(label == "PlayIdle")
				_customPlayerEnt.get(Timeline).gotoAndPlay("idle");
		}
		override protected function finalizeGame(...args):void
		{
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(char));
		 	if(_customPlayer)
			{
				var timeline:Timeline = _customPlayerEnt.get(Timeline);
				//timeline.handleLabel("gotoAndPlayIdle",PlayIdle,false);
				timeline.labelReached.add( PlayerHandler );
				timeline.play();
				
				
			}
			open(super.groupReady);
		}
		
		private function onHit(entity:Entity, id:String):void
		{
			var hit:Entity = getEntityById(id);
			Timeline(hit.get(Timeline)).gotoAndPlay("hit");
			
			if(hitSounds.hasOwnProperty(id))
			{
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + hitSounds[id]);
			}
			else
			{
				//check to see if the id derives from any of the keys
				for(var key:String in hitSounds)
				{
					if(id.indexOf(key) >= 0)
					{
						AudioUtils.play(this, SoundManager.EFFECTS_PATH + hitSounds[key]);
						break;
					}
				}
			}
			
			if(hitFeedBack)
			{
				var spatial:Spatial = hitFeedBack.get(Spatial);
				var target:Spatial = char.get(Spatial);
				spatial.x = target.x;
				spatial.y = target.y;
				Timeline(hitFeedBack.get(Timeline)).gotoAndPlay(0);
			}
			var timeline:Timeline;
			// play avatar hurt animation then resume idle after
			if(_customPlayer)
			{
				timeline = _customPlayerEnt.get(Timeline);
				timeline.gotoAndPlay("hurt");
				timeline.handleLabel("ending", resume);
			}
			else
			{
				setAnimation(HURT);
				timeline = char.get(Timeline);
				timeline.handleLabel("ending", resume);
			}
		}
		
		private function setAnimation(type:String):void
		{
			var charId:String = char.get(Id).id;
			
			var animation:Class = animations.hasOwnProperty(charId+type)?animations[charId+type]:animations[type];
			
			CharUtils.setAnim(char, animation);
		}
		
		private function resume():void
		{
			if(life >= lives)
			{
				endGame(false);
			}
			else
			{
			setAnimation(IDLE);
			// reopen eyes after getting hurt, because they get stuck like that other wise
			var eyeState:String = SkinUtils.getLook(char).getValue(SkinUtils.EYE_STATE);
			SkinUtils.setEyeStates(char, eyeState);
			
			//after getting hurt update lives and end game if you run out of lives
			life++;
			if(hud)
				hud.gotoAndStop(life);
			}

		}
		
		private function endGame(win:Boolean):void
		{
			close();
			if(win)
				winGame();
			else
				gameOver();
		}
	}
}