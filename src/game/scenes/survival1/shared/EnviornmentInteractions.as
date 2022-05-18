package game.scenes.survival1.shared
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.data.AudioWrapper;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.timeline.BitmapSequence;
	import game.components.entity.Children;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.sound.SoundModifier;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeck;
	import game.scenes.shrink.schoolCafetorium.HitTheDeckSystem.HitTheDeckSystem;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.components.TimedEntity;
	import game.scenes.survival1.shared.components.WindBlock;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.survival1.shared.systems.TimedEntitySystem;
	import game.systems.SystemPriorities;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.util.AudioUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.TimelineUtils;
	import game.util.Utils;
	
	public class EnviornmentInteractions extends Group
	{
		private const ICICLE:String = "icicle";
		private const LEAF:String = "leaf";
		private const GRASS:String = "grass";
		private const BRANCH:String = "branch";
		private const OWL:String = "owlAnimation";
		private const OWL_HIT:String = "owlHit";
		private const OWL_MASK:String = "owlMask";
		
		private var grassSequences:Vector.<BitmapSequence>;
		private var icicleSequences:Vector.<BitmapSequence>;
		private var leafSequence:BitmapSequence = null;
		
		private const START:String = "start";
		private const LOOP:String = "loop";
		private const END:String = "end";
		private const ENDING:String = "ending";
		
		private const RIGHT:String = "right";
		private const LEFT:String = "left";
		private const LEFT_RIGHT:String = "leftright";
		
		private const RUSTLE:String = "leaves_rustle_0";
		private const RUSTLES:int = 2;
		private const ICE_BREAK:String = "icicle_0";
		private const BREAKS:int = 1;
		private const HOOT:String = "owl_hoot_0";
		private const HOOTS:int = 5;
		private const MP3:String = ".mp3";
		
		private var scene:SurvivalScene;
		private var container:DisplayObjectContainer;
		private var player:Entity;
		private var range:AudioRange;
		
		private var _folliage:Vector.<Entity>;
		private var _windRight:Boolean;
		private var _strongWind:Boolean;
		
		//private var _ignoreWindInteractionLevel:int = 0;
		private var _ignoreWindInteractions:Boolean = false;
		
		private var _overSampleScale:Number;
		
		private var _bitmapClips:Boolean = true;
		
		public function EnviornmentInteractions(scene:SurvivalScene, container:DisplayObjectContainer, player:Entity, ignoreLevel:int = 0)
		{
			_overSampleScale = .5 + PerformanceUtils.qualityLevel / 50;
			_ignoreWindInteractions = (PerformanceUtils.qualityLevel < ignoreLevel )
			this.player = player;
			this.container = container;
			this.scene = scene;
			this.id = "environmentalInteractionsGroup";
			
			if(scene.wind == null)
				return;
			
			scene.wind.strongWind.add(startBlowing);
			scene.wind.weakWind.add(stopBlowing);
			
			scene.addSystem(new HitTheDeckSystem());
			scene.addSystem(new TriggerHitSystem());
			scene.addSystem(new BitmapSequenceSystem(), SystemPriorities.animate );
			scene.addSystem(new TimedEntitySystem());
			
			_folliage = new Vector.<Entity>();
			
			grassSequences = new Vector.<BitmapSequence>();
			grassSequences.push(null, null, null);
			
			icicleSequences = new Vector.<BitmapSequence>();
			icicleSequences.push(null, null);
			
			range = new AudioRange(500, 0, .5, Quad.easeIn);

			for each (var child:DisplayObject in container)
			{
				if( child != null )	// NOTE :: Not sure why this would be null, but it is? -bard
				{
					if(child.name.indexOf(ICICLE) == 0)
					{
						setUpIcicle(child as MovieClip);
					}
					else if(child.name.indexOf(LEAF) == 0)
					{
						setUpLeaf(child as MovieClip);
					}
					else if(child.name.indexOf(GRASS) == 0)
					{
						setUpGrass(child as MovieClip);
					}
					else if(child.name.indexOf(BRANCH) == 0)
					{
						setupBranches(child as MovieClip);
					}
					else if(child.name.indexOf(OWL) == 0)
					{
						setUpOwls(child as MovieClip);
					}
				}
				else
				{
					trace( "EnviornmentInteractions :: child was null : " + child );
				}
			}
		}
		
		private function stopBlowing(right:Boolean):void
		{
			_strongWind = false;
			_windRight = right;
		}
		
		private function startBlowing(right:Boolean):void
		{
			if(_ignoreWindInteractions)
			{
				_strongWind = true;
				_windRight = right;
				return;
			}
			if(!_strongWind)
			{
				_strongWind = true;
				for(var i:int = 0; i < _folliage.length; i++)
				{
					var entity:Entity = _folliage[i];
					var id:Id = entity.get(Id);
					var time:Timeline = entity.get(Timeline);
					var block:WindBlock = entity.get(WindBlock);
					
					playSound(entity, RUSTLE, RUSTLES);
					
					if(id.id.indexOf(GRASS) == 0)
					{
						if(right && !block.left)
							time.gotoAndPlay(START+RIGHT);
						if(!right && !block.right)
							time.gotoAndPlay(START+LEFT);
					}
					else
					{
						if(right && !block.left || !right && !block.right)
							time.gotoAndPlay(0);
					}
				}
			}
			_strongWind = true;
			_windRight = right;
		}
		
		public function isStrongWind():Boolean
		{
			return _strongWind;
		}
		
		public function isBlowingRight():Boolean
		{
			return _windRight;
		}
		
		private function setUpOwls(clip:MovieClip):void
		{
			var id:String = clip.name.substr(OWL.length);
			
			clip.mask = container[OWL_MASK + id];
			
			var hitClip:MovieClip = container[OWL_HIT + id];
			
			if(_ignoreWindInteractions)
			{
				container.removeChild(clip);
				container.removeChild(container[OWL_MASK + id]);
				container.removeChild(hitClip);
				return;
			}
			
			var owlHit:Entity = EntityUtils.createSpatialEntity(scene, hitClip, container);
			ToolTipCreator.addToEntity(owlHit);
			var interaction:Interaction = InteractionCreator.addToEntity(owlHit, ["click"]);
			interaction.click.add(owlListener);
			
			var owlRange:AudioRange = new AudioRange(1000,0,1,Quad.easeIn);
			
			var baseHootTime:Number = 3;
			var hootTimeRange:Number = 7;
			
			var owl:Entity = EntityUtils.createSpatialEntity(scene, clip, container);
			TimelineUtils.convertClip( clip, scene, owl, owlHit, false );
			
			//BitmapTimelineCreator.convertToBitmapTimeline(owl, clip, true,null, 2.5);
			//EntityUtils.addParentChild(owl, owlHit);
			// mask does not work when bitmapped
			
			var timedEntity:TimedEntity = new TimedEntity(baseHootTime, hootTimeRange);
			timedEntity.timesUp.add(hoot);
			owl.add(timedEntity).add(new Audio()).add(owlRange).add( new Id( "owl" + id ));
			var time:Timeline = owl.get(Timeline);
			time.handleLabel("hoot", Command.create(hoot, owl), false);
		}
		
		private function hoot(owl:Entity):void
		{
			playSound(owl, HOOT, HOOTS, false);
		}
		
		private function owlListener( owlHit:Entity ):void
		{
			var owl:Entity = Children( owlHit.get( Children )).children[ 1 ];
			var timeline:Timeline = owl.get( Timeline );
			timeline.play();
		}
		
		private function setUpGrass(clip:MovieClip):void
		{
			var block:WindBlock = setUpWindBlock(clip.name);
			
			var grass:Entity = EntityUtils.createSpatialEntity(scene, clip, container);
			grass.add(new Id(clip.name)).add(new Audio()).add(range).add(block).add(new Sleep());
			///*
			var sequenceNumber:int = int(clip.name.charAt(5))
			var sequence:BitmapSequence = grassSequences[sequenceNumber];
			BitmapTimelineCreator.convertToBitmapTimeline(grass, clip, true, sequence, _overSampleScale);
			if(sequence == null && _bitmapClips)
				grassSequences[sequenceNumber] = grass.get(BitmapSequence);
			//*/
			//TimelineUtils.convertClip(clip, scene, grass);
			
			var time:Timeline = grass.get(Timeline);
			time.labelReached.add(Command.create(grassLabelReached, grass));
			_folliage.push(grass);
		}
		
		private function setupBranches( clip:MovieClip ):void
		{
			var entity:Entity;
			var number:String = clip.name.substr( 6 );
			var timeline:Timeline;
			var bounceEntity:Entity = scene.getEntityById( "bounce" + number );
			
			entity = EntityUtils.createSpatialEntity( scene, clip, container );
			entity.add( new Id( clip.name ));
			TimelineUtils.convertClip( clip, this, entity, null, false );
			
			bounceEntity.add( new TriggerHit( entity.get( Timeline )));
		}
		
		private function grassLabelReached(label:String, grass:Entity):void
		{
			var timeline:Timeline = grass.get(Timeline);
			var block:WindBlock = grass.get(WindBlock);
			if(_strongWind && _windRight && !block.left || _strongWind && !_windRight && !block.right)
			{
				playSound(grass, RUSTLE, RUSTLES);
				
				if(label == END+RIGHT && _windRight)
					timeline.gotoAndPlay(LOOP+RIGHT);
				
				if(label == LEFT+END && !_windRight)
					timeline.gotoAndPlay(LEFT+LOOP);
			}
			else
			{
				if(label == ENDING || label == START+LEFT)
				{
					timeline.gotoAndStop(0);
					Audio(grass.get(Audio)).stopAll("effects");
				}
			}
		}
		
		private function setUpLeaf(clip:MovieClip):void
		{
			if(_ignoreWindInteractions)
			{
				container.removeChild(clip);
				return;
			}
			var block:WindBlock = setUpWindBlock(clip.name);
			
			var leaf:Entity = EntityUtils.createSpatialEntity(scene, clip, container);
			leaf.add(new Sleep()).add(new Audio()).add(range).add(block).add(new Id(clip.name));			
			//TimelineUtils.convertClip(clip, scene, leaf,null);
			///*
			BitmapTimelineCreator.convertToBitmapTimeline(leaf,clip,true, leafSequence,_overSampleScale);
			if(leafSequence == null && _bitmapClips)
				leafSequence = leaf.get(BitmapSequence);
			//*/
			var time:Timeline = leaf.get(Timeline);
			time.handleLabel(ENDING,Command.create(leafLoop, leaf),false);
			_folliage.push(leaf);
		}
		
		private function leafLoop(leaf:Entity):void
		{
			var block:WindBlock = leaf.get(WindBlock);
			if(_strongWind && _windRight && !block.left || _strongWind && !_windRight && !block.right)
				playSound(leaf, RUSTLE, RUSTLES);
			else
			{
				Timeline(leaf.get(Timeline)).gotoAndStop(0);
				Audio(leaf.get(Audio)).stopAll("effects");
			}
		}
		
		private function playSound(entity:Entity, sound:String, soundPossibilities:int, loop:Boolean = true):void
		{
			var soundNumber:int = Utils.randInRange(1,soundPossibilities);
			var audio:Audio = entity.get(Audio);
			var audioWrapper:AudioWrapper = new AudioWrapper();
			
			if(audio != null)
			{
				if(audio._playing.length == 0)
					audioWrapper = audio.play(SoundManager.EFFECTS_PATH+sound+soundNumber+MP3,false,SoundModifier.POSITION);
			}
			else
				audioWrapper = AudioUtils.play(this,SoundManager.EFFECTS_PATH+sound+soundNumber+MP3,1,loop,SoundModifier.FADE);
			
			if(loop && _strongWind)
				audioWrapper.complete.addOnce(Command.create(playSound, entity, sound, soundPossibilities));
		}
		
		private function setUpWindBlock(folliageName:String):WindBlock
		{
			var blockType:String = LEFT_RIGHT;
			
			var index:int = folliageName.indexOf(blockType,5);
			
			if(index == -1)
			{
				blockType = RIGHT;
				index = folliageName.indexOf(blockType,5);
				if(index == -1)
				{
					blockType = LEFT;
					index = folliageName.indexOf(blockType,5);
					if( index == -1)
						blockType = "";
				}
			}
			
			var left:Boolean = false;
			var right:Boolean = false;
			
			if(blockType.indexOf(RIGHT) != -1)
				right = true;
			if(blockType.indexOf(LEFT) != -1)
				left = true;
			
			return new WindBlock(right, left);
		}
		
		private function setUpIcicle(clip:MovieClip):void
		{
			if(_ignoreWindInteractions)
			{
				container.removeChild(clip);
				return;
			}
			var icicle:Entity = EntityUtils.createSpatialEntity(scene, clip, container);
			//TimelineUtils.convertClip(clip, scene, icicle, null, false);
			
			///*
			var sequenceNumber:int = int(clip.name.charAt(6))
			var sequence:BitmapSequence = icicleSequences[sequenceNumber];
			BitmapTimelineCreator.convertToBitmapTimeline(icicle,clip,true, sequence,_overSampleScale);
			if(sequence == null && _bitmapClips)
				icicleSequences[sequenceNumber] = icicle.get(BitmapSequence);
			//*/
			var fall:HitTheDeck = new HitTheDeck(player.get(Spatial),100,false, new Point(0, -clip.height / 2 - 25));
			fall.duck.addOnce(dropIcicle);
			icicle.add(fall).add(new Sleep()).add(new Id(clip.name));
			var time:Timeline = icicle.get(Timeline);
			time.handleLabel("ending",Command.create(brokeIcicle,time));			
		}
		
		private function brokeIcicle(time:Timeline):void
		{
			time.gotoAndStop(time.currentIndex);
		}
		
		public function dropIcicle(icicle:Entity):void
		{
			Timeline(icicle.get(Timeline)).play();
			playSound(icicle, ICE_BREAK, BREAKS, false);
		}
	}
}