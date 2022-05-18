package game.scenes.con1.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.motion.Threshold;
	import game.creators.entity.character.CharacterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Walk;
	import game.scene.template.CharacterGroup;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	public class RandomNPCGroup extends Group
	{
		/**
		 * 
		 * @param name - id name, so you can use group multiple times
		 * @param container - the container to put the NPCs in
		 * @param scene - the scene that this group will be added to
		 * @param yLoc - the y location of the NPCs
		 * @param minNum - the minimum number of NPCs that can come out
		 * @param maxNum - the maximum number of NPCs that can come out as a group
		 * @param percentMin - the minimum percent of the scene's width the NPCs will walk to
		 * @param percentMax - the maximum percent of the scene's width the NPCs will walk to
		 * @param speed - the speed at which the NPCs will walk
		 * @param charInFrontOf - where in the hit container should they be placed in front of
		 * 
		 */
		public function RandomNPCGroup(name:String, yLoc:Number, minNum:Number = 1, maxNum:Number = 5, percentMin:Number = 25, percentMax:Number = 75, minSpeed:Number = 200, maxSpeed:Number = 250, waitTime:Number = 3, index:Number = NaN)
		{
			this.id = name;
			_yLoc = yLoc;
			_minGroupSize = minNum;
			_maxGroupSize = maxNum;
			_distPercentMax = percentMax;
			_distPercentMin = percentMin;
			_npcMinSpeed = minSpeed;
			_npcMaxSpeed = maxSpeed;
			_waitTime = waitTime;
			_charIndex = index;
		}
		
		public override function destroy():void
		{
			if(_timedEvent)
			{
				_timedEvent.signal.removeAll();
				_timedEvent.stop();
				_timedEvent = null;
			}
			
			if(_characters)
				_characters = null;
			
			if(_currentCharacters)
				_currentCharacters = null;
			
			if(_creator)
			{
				_creator.destroy();
				_creator = null;
			}	
			
			super.destroy();
		}
		
		public function setup(container:DisplayObjectContainer, scene:Scene, creator:RandomNPCCreator):void
		{
			_scene = scene;
			_container = container;
			
			_characterGroup = _scene.getGroupById("characterGroup") as CharacterGroup;
			_characters = new Vector.<Entity>();
			_scene.addSystem(new ThresholdSystem());
			
			_creator = creator;
			if(_creator.isLoaded)
				creatorLoaded();
			else
				_creator.loaded.addOnce(creatorLoaded);			
		}
		
		private function creatorLoaded():void
		{		
			_charsLoaded = 0;
			loadCharacter(_charsLoaded);
		}
		
		private function loadCharacter(charNum:int):void
		{
			_characterGroup.createDummy("rando" + charNum, _creator.createRandomNPC(), "right", "", _container, _scene, charLoaded, true, NaN, CharacterCreator.TYPE_DUMMY, new Point(_scene.sceneData.cameraLimits.left - 100, _yLoc));			
		}
		
		private function charLoaded(char:Entity):void
		{
			_characters.push(char);
				
			var displayObject:MovieClip = char.get(Display).displayObject;
			displayObject.mouseChildren = false;
			displayObject.mouseEnabled = false;			
			
			EntityUtils.turnOffSleep(char);			
			char.add(new Motion());
			_charsLoaded++;
			
			if(_charsLoaded < _maxGroupSize)
			{
				loadCharacter(_charsLoaded);
			}
			else
			{
				this.groupReady();
				setupNewCharacters();
			}
		}
		
		private function setupNewCharacters():void
		{
			var randomIsland:String = _creator.getRandomIsland();
			var numPeople:int = randBetween(_minGroupSize, _maxGroupSize);
			var right:Boolean = Math.floor((Math.random() * 2)) % 2;
			_currentCharacters = new Vector.<Entity>();
						
			applyLook(randomIsland, numPeople, right);				
		}
		
		private function applyLook(randomIsland:String, numPeople:int, right:Boolean):void
		{
			var partsRandom:Boolean = int(Math.random() * 2) % 2;			
			var current:int = _currentCharacters.length;
			
			clearNPC(_characters[current], right, current * 80);
			SkinUtils.applyLook(_characters[current], _creator.createRandomNPC(randomIsland, partsRandom), true, Command.create(readyToWalk, randomIsland, numPeople, right));
		}
		
		private function readyToWalk(char:Entity, randomIsland:String, num:int, right:Boolean):void
		{
			if(!isNaN(_charIndex))
				_container.addChildAt(char.get(Display).displayObject, _charIndex);
			else
				_container.addChildAt(char.get(Display).displayObject, _container.numChildren - 1);
			
			_currentCharacters.push(char);
			if(_currentCharacters.length == num)
			{			
				madeHalfway = 0;
				charCount = 0;
				offsetX = 0;
				var speedOffset:Number = right ? -1 : 1;
				var randLoc:Number = _scene.sceneData.cameraLimits.right * (randBetween(_distPercentMax, _distPercentMin) / 100);
				
				trace(num + " walking to: " + randLoc);
				
				_timedEvent = new TimedEvent(.25, num, Command.create(startWalk, speedOffset, randLoc));
				SceneUtil.addTimedEvent(this, _timedEvent);
			}
			else
			{
				applyLook(randomIsland, num, right);
			}
		}		
		
		private function startWalk(speedOffset:Number, randLoc:Number):void
		{
			var npc:Entity = _currentCharacters[charCount];
			Motion(npc.get(Motion)).velocity.x = randBetween(_npcMinSpeed, _npcMaxSpeed) * speedOffset;
			CharUtils.setAnim(npc, Walk);
			
			var threshold:Threshold = npc.get(Threshold);
			threshold.threshold = randLoc + offsetX;
			threshold.entered.addOnce(Command.create(halfwayDone, npc));
			offsetX += 80;
			charCount++;
		}
		
		private function halfwayDone(entity:Entity):void
		{
			entity.get(Motion).zeroMotion();
			CharUtils.setAnim(entity, Stand);
			
			madeHalfway++;
			if(madeHalfway % 2 == 1)
				CharUtils.setDirection(entity, true);
			
			if(_currentCharacters.length == madeHalfway)
			{
				_timedEvent = new TimedEvent(_waitTime, 1, walkOff);
				SceneUtil.addTimedEvent(this, _timedEvent);
			}
		}
		
		private function walkOff():void
		{
			var randomSpot:Number = _scene.sceneData.bounds.left + 20;
			if(Math.random() < .5) randomSpot = _scene.sceneData.bounds.right - 20;
			charCount = 0;
				
			_timedEvent = new TimedEvent(.25, _currentCharacters.length, Command.create(walkOffScreen, randomSpot));
			SceneUtil.addTimedEvent(this, _timedEvent);
		}
		
		private function walkOffScreen(randomSpot:Number):void
		{
			try
			{
				var npc:Entity = _currentCharacters[charCount];
				CharUtils.setAnim(npc, Walk);
				var threshold:Threshold = npc.get(Threshold);
				threshold.threshold = randomSpot;
				
				if(randomSpot < npc.get(Spatial).x)
				{
					CharUtils.setDirection(npc, false);
					npc.get(Motion).velocity.x = -randBetween(_npcMinSpeed, _npcMaxSpeed);
					threshold.operator = "<";
				}
				else
				{
					CharUtils.setDirection(npc, true);
					npc.get(Motion).velocity.x = randBetween(_npcMinSpeed, _npcMaxSpeed);
					threshold.operator = ">";
				}
				
				threshold.entered.addOnce(Command.create(movedOffScreen, npc));
				charCount++;
			} 
			catch(error:Error) 
			{
				trace("RandomNPCGroup :: walkOffScreen : index was out of range for picking which entity npc to walk off screen.");
			}			
		}
		
		private function movedOffScreen(entity:Entity):void
		{
			_currentCharacters.splice(_currentCharacters.indexOf(entity), 1);
			if(_currentCharacters.length == 0)
			{
				setupNewCharacters();
			}
		}
		
		private function randBetween(min:Number, max:Number):Number
		{
			return (Math.floor(Math.random() * (max - min + 1)) + min);
		}
		
		private function clearNPC(char:Entity, rightSide:Boolean = false, xOffset:Number = 0):void
		{
			SkinUtils.emptySkinPart(char, SkinUtils.OVERPANTS);
			SkinUtils.emptySkinPart(char, SkinUtils.OVERSHIRT);
			SkinUtils.emptySkinPart(char, SkinUtils.ITEM);
			SkinUtils.emptySkinPart(char, SkinUtils.ITEM2);
			SkinUtils.emptySkinPart(char, SkinUtils.PACK);
			SkinUtils.emptySkinPart(char, SkinUtils.SHIRT);
			SkinUtils.emptySkinPart(char, SkinUtils.MARKS);
			
			var threshold:Threshold = new Threshold("x", ">");
			if(rightSide) threshold.operator = "<";
			char.add(threshold);

			var charSpatial:Spatial = char.get(Spatial);
			if(rightSide)
			{
				CharUtils.setDirection(char, false);
				charSpatial.x = _scene.sceneData.cameraLimits.right + 100 + xOffset;
			}
			else
			{
				CharUtils.setDirection(char, true);
				charSpatial.x = _scene.sceneData.cameraLimits.left - 100 - xOffset;
			}
		}
		
		private var _yLoc:Number = 0;
		
		private var _distPercentMax:Number;
		private var _distPercentMin:Number;
		private var _charsLoaded:Number = 0;
		private var _minGroupSize:Number;
		private var _maxGroupSize:Number;
		private var _scene:Scene;
		private var _container:DisplayObjectContainer;
		private var _creator:RandomNPCCreator;
		private var _characterGroup:CharacterGroup;
		private var _characters:Vector.<Entity>;
		private var _currentCharacters:Vector.<Entity>;
		private var _charIndex:Number;
		private var _npcMinSpeed:Number;
		private var _npcMaxSpeed:Number;
		private var _waitTime:Number;
		private var _timedEvent:TimedEvent;
		
		private var offsetX:Number = 0;
		private var charCount:int = 0;
		private var madeHalfway:int = 0;
	}
}