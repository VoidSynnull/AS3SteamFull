package game.scene.template.ads.shared
{
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import engine.group.DisplayGroup;
	import engine.group.Group;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.HitTest;
	import game.components.motion.MotionControl;
	import game.data.character.LookData;
	import game.scene.template.ads.AdInteriorScene;
	import game.scenes.custom.questGame.QuestGame;
	import game.systems.hit.HitTestSystem;
	import game.ui.hud.Hud;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class AdGameTemplate extends DisplayGroup
	{
		protected var _scene:QuestGame;
		protected var _hitContainer:DisplayObjectContainer;
		protected var _looks:Vector.<LookData>;
		protected var _selection:int = -1;
		protected var _returnX:Number;
		protected var _returnY:Number;
		protected var _hideHud:Boolean = false;
		
		public var gameSetUp:Signal;
		
		public function AdGameTemplate(container:DisplayObjectContainer=null)
		{
			super(container);
			gameSetUp = new Signal(Group);
		}
		
		public virtual function setupGame(scene:QuestGame, xml:XML, hitContainer:DisplayObjectContainer):void
		{
			_scene = scene;
			
			// set group variables
			this.groupPrefix = scene.groupPrefix;
			this.container = scene.container;
			this.groupContainer = hitContainer;
			_hitContainer = hitContainer;
			
			setUpSlides();
			
			// need to parse xml to get game parameters
			parseXML(xml);
			
			// hide hud button
			var hud:Hud = Hud(scene.getGroupById(Hud.GROUP_ID));
			hud.showHudButton(_hideHud);
		}
		
		private function setUpSlides():void
		{
			var i:int = 1;
			var entity:Entity = _scene.getEntityById("slide"+i);
			while(entity != null)
			{
				if(i==1)
				{
					_scene.addSystem(new HitTestSystem());
				}
				entity.add(new HitTest(onSlide, false, onSlide));
				
				i++;
				entity = _scene.getEntityById("slide"+i);
			}
		}
		
		private function onSlide(entity:Entity, id:String):void
		{
			var char:Entity = _scene.getEntityById(id);
			var control:CharacterMotionControl = char.get(CharacterMotionControl);
			var motion:MotionControl = char.get(MotionControl);
			// making it so they are not following the cursor while on the slide or just leaving the slide
			if(control != null)
			{
				control.allowAutoTarget = false;
				motion.inputStateDown = false;
			}
		}
		
		protected virtual function parseXML(xml:XML):void
		{
			if(xml.hasOwnProperty("looks"))
			{
				setUpLooks(xml.looks);
			}
		}
		
		protected virtual function setUpLooks(xml:XMLList):void
		{
			_looks = new Vector.<LookData>();
			for(var i:int = 0; i < xml.children().length(); i++)
			{
				_looks.push(new LookData(xml.children()[i]));
			}
		}
		
		public virtual function playerSelection(selection:int = 1):void
		{
			_selection = selection;
			if(_looks != null)
			{
				if(selection > 0 && selection < _looks.length + 1)
				{
					SkinUtils.applyLook(_scene.shellApi.player, _looks[selection-1],false,playerSelected);
				}
				else
				{
					if(selection == -1)
					{
						//_scene.shellApi.loadScene(QuestInterior, _returnX, _returnY);
						return;
					}
					playerSelected();
				}
			}
			else
				playerSelected();
		}
		
		protected virtual function playerSelected(...args):void
		{
			
		}
		
		/**
		 * Parse game xml for quest games
		 */
		protected function parseGameXML(gameXML:XML):void
		{
			// if xml object, then setup
			if (gameXML != null)
			{
				// parse game xml
				var items:XMLList = gameXML.children();
				// for each group in xml
				for (var i:int = items.length() - 1; i != -1; i--)
				{
					var propID:String = "_" + items[i].name();
					var value:String = items[i].valueOf();
					// get type (needed for arrays when there is only one value)
					var type:String = String(items[i].attribute("type"));
					try
					{
						// check number value
						var numberVal:Number = Number(value);
						// if true
						if (value.toLowerCase() == "true")
						{
							this[propID] = true;
						}
						else if (value.toLowerCase() == "false")
						{
							// if false
							this[propID] = false;
						}
						else if (type == "array")
						{
							this[propID] = [value];
						}
						else if (isNaN(numberVal))
						{
							// if string
							// if contains pipe or type is array, then assume array
							if (value.indexOf("|") != -1)
							{
								var arr:Array = value.split("|");
								// convert to numbers if array has numbers
								for (var j:int = arr.length-1; j != -1; j--)
								{
									numberVal = Number(arr[j]);
									// if number, then swap
									if (!isNaN(numberVal))
										arr[j] = numberVal;
								}
								this[propID] = arr;
							}
							else
							{
								this[propID] = value;
							}
						}
						else
						{
							// if number
							this[propID] = numberVal;
						}
					}
					catch (e:Error)
					{
						trace("public game property " + propID + " does not exist in class!");
					}
				}
				var hud:Hud = Hud(_scene.getGroupById(Hud.GROUP_ID));
				hud.showHudButton(_hideHud);
			}
			else
			{
				trace("Game XML not loaded");
			}
		}
	}
}