package game.scenes.prison.cellBlock.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.motion.SpatialToMouse;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.ui.ToolTipType;
	import game.scenes.prison.PrisonEvents;
	import game.scenes.prison.shared.particles.ChiselBlast;
	import game.systems.motion.SpatialToMouseSystem;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class VentChiselPopup extends Popup
	{
		public function VentChiselPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);	
			
			this.groupPrefix = "scenes/prison/cellBlock/popups/";					
			this.pauseParent = true;
			this.darkenBackground = true;
			this.autoOpen = true;
			
			load();
		}
		
		override public function destroy():void
		{
			if(_guardTimer && _guardTimer.completed)
			{
				_guardTimer.completed.remove(timerDone);
			}
			super.destroy();
		}
		
		override public function load():void
		{
			_chiseled = DataUtils.getArray(shellApi.getUserField(_prisonEvents.VENT_CHISELS, shellApi.island));
			this.loadFiles(["ventPopup.swf"], false, true, loaded);
		}
		
		override public function loaded():void
		{
			this._defaultCursor = ToolTipType.ARROW;
			this.screen = getAsset("ventPopup.swf", true) as MovieClip;
			this.letterbox(screen.content, new Rectangle(40, 10, 860, 540), false);
			
			setupChiselSpots();
			
			loadCloseButton();
			super.loaded();
			
			var prisonEvents:PrisonEvents;
			var spoonClip:MovieClip;
			if(!shellApi.checkHasItem(prisonEvents.SHARPENED_SPOON))
			{
				screen.content.removeChild(screen.content["spoon_sharpened"]);
				if(!shellApi.checkHasItem(prisonEvents.SPOON))
				{
					screen.content.removeChild(screen.content["spoon"]);
					SceneUtil.lockInput(this, true);
					SceneUtil.delay(this, 2, close);
					return;
				}
				else
				{
					spoonClip = screen.content["spoon"];
					_oneClick = true;
				}
			}
			else
			{
				spoonClip = screen.content["spoon_sharpened"];
			}
			
			if(spoonClip)
			{
				spoonClip.mouseChildren = false;
				spoonClip.mouseEnabled = false;
				_spoonEntity = EntityUtils.createSpatialEntity(this, spoonClip);
				_spoonEntity.add(new SpatialToMouse(screen.content));
				_spoonEntity.add(new SpatialAddition());
				this.addSystem(new SpatialToMouseSystem());
			}
			
			_guardTimer = this.parent.getGroupById(GuardUITimer.GROUP_ID) as GuardUITimer;
			if(_guardTimer)
			{
				_guardTimer.completed.addOnce(timerDone);
			}
			else
			{
				SceneUtil.lockInput(this, true);
				SceneUtil.delay(this, 1, close);
			}
		}
		
		private function setupChiselSpots():void
		{
			_numSpotsEmpty = 0;
			_dictionary = new Dictionary();
			for(var i:int = 0; i < NUM_CLICK_SPOTS; i++)
			{
				var id:String = "click" + i;
				var clickClip:MovieClip = screen.content[id];
				
				var click:Entity = EntityUtils.createSpatialEntity(this, clickClip);
				click.add(new Id(id));
				var interaction:Interaction = InteractionCreator.addToEntity(click, [InteractionCreator.CLICK]);
				interaction.click.add(spotClicked);
				ToolTipCreator.addToEntity(click);				
				
				_dictionary[id] = new Array();
				for each(var child:MovieClip in clickClip)
				{
					if(child.name.indexOf("chisel") != -1)
					{
						if(_chiseled.indexOf(child.name) == -1)
						{
							var chiselSpot:Entity = EntityUtils.createSpatialEntity(this, child);
							chiselSpot.add(new Id(child.name));
							_dictionary[id].push(chiselSpot);
						}
						else
						{
							clickClip.removeChild(child);
						}
					}
				}
				
				if(_dictionary[id].length == 0)
					_numSpotsEmpty++;
			}
		}
		
		private function spotClicked(clickSpot:Entity):void
		{	
			_spoonEntity.get(Spatial).y += 30;
			_clickCount++;
			var point:Point = new Point(screen.content.mouseX, screen.content.mouseY);
			var chiselBlast:ChiselBlast = new ChiselBlast();
			chiselBlast.init(3, 7, 2, 0xC8D4BF);
			EmitterCreator.create(this, screen.content, chiselBlast, point.x, point.y);
			
			var soundFile:String = !_oneClick ? "break_block_0" + GeomUtils.randomInt(1, 3) + ".mp3" : "metal_impact_11.mp3";				
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + soundFile);
			
			CharUtils.lockControls(shellApi.player, true);
			TweenUtils.entityTo(_spoonEntity, SpatialAddition, .1, {y:-15, onComplete:tweenBack});
			
			if(_guardTimer)
			{
				_guardTimer.fadeOut();
				if(_fadeBackInTimer) 
				{
					_fadeBackInTimer.stop();
					_fadeBackInTimer = null;
				}
				_fadeBackInTimer = new TimedEvent(1.25, 1, _guardTimer.fadeIn);
				SceneUtil.addTimedEvent(this, _fadeBackInTimer);
			}
			
			if(_clickCount % 2 == 0)
			{
				if(_oneClick)
				{
					close();
					return;
				}
				
				var clickId:String = clickSpot.get(Id).id;
				var array:Array = _dictionary[clickId];
				
				if(array)
				{
					var chiselPart:Entity = findClosest(DisplayUtils.localToLocalPoint(point, screen.content, clickSpot.get(Display).displayObject), array);
					_chiseled.push(chiselPart.get(Id).id);
					array.splice(array.indexOf(chiselPart),1);
					removeEntity(chiselPart);
					
					if(array.length == 0)
					{
						clickSpot.get(Interaction).click.removeAll();
						removeEntity(clickSpot);
						_dictionary[clickId] = null;
						_numSpotsEmpty++;
					}
				}
				
				// win
				if(_numSpotsEmpty == NUM_CLICK_SPOTS)
				{
					shellApi.completeEvent(_prisonEvents.CELL_GRATE_OPEN, shellApi.island);	
					close();
				}
			}			
		}
		
		private function tweenBack():void
		{
			TweenUtils.entityTo(_spoonEntity, SpatialAddition, .1, {y:0});
			CharUtils.lockControls(shellApi.player, false, false);
		}
		
		private function findClosest(point:Point, array:Array):Entity
		{
			var closest:Entity = null;
			var closerDist:Number = -1
			
			for each(var chisel:Entity in array)
			{
				var chiselSpatial:Spatial = chisel.get(Spatial);
				var dist:Number = GeomUtils.distSquared(chiselSpatial.x, chiselSpatial.y, point.x, point.y);
				
				if(closest == null || dist < closerDist)
				{
					closest = chisel;
					closerDist = dist;
				}
			}
			
			return closest;
		}
		
		private function timerDone():void
		{
			caught = true;
			SceneUtil.lockInput(this, true);
			SceneUtil.delay(this, 1, close);
		}

		override public function close(removeOnClose:Boolean=true, onClosedHandler:Function=null):void
		{		
			if(_guardTimer) _guardTimer.showFull();
			SceneUtil.lockInput(this, false, false);
			shellApi.setUserField(_prisonEvents.VENT_CHISELS, _chiseled.join(","), shellApi.island);
			super.close(removeOnClose, onClosedHandler);
		}
		
		private const NUM_CLICK_SPOTS:int = 12;
		
		private var _numSpotsEmpty:int = 0;
		private var _dictionary:Dictionary;
		private var _chiseled:Array;
		private var _prisonEvents:PrisonEvents = new PrisonEvents();
		private var _clickCount:int = 0;
		
		private var _oneClick:Boolean;
		private var _guardTimer:GuardUITimer;
		private var _fadeBackInTimer:TimedEvent;
		private var _spoonEntity:Entity;
		
		public var caught:Boolean = false;
	}
}