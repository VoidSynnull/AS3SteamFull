package game.systems.actionChain.actions
{
	import flash.display.DisplayObject;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.systems.actionChain.ActionCommand;
	import game.util.PerformanceUtils;
	
	// Add glow filter to any object or enitity or entities
	// Can be used for any NPC, the player's avatar, all NPCs ("NPCS") or all ("ALL") or facing ("FACING") characters
	public class AddGlowFilterAction extends ActionCommand
	{
		private var display:DisplayObject;
		private var color:uint;
		private var alpha:Number;
		private var blur:Point;
		private var strength:Number;
		private var inner:Boolean;
		private var knockout:Boolean;
		
		private var _charType:String;
		
		/**
		 * Add glow filter to any object or enitity or entities
		 * @param object 		Object to apply filter to (can be a string constant "ALL" or "NPCS" or "FACING" to indicate an array of entities) 
		 * @param color			Glow color
		 * @param alpha			Glow alpha
		 * @param blur			Glow blur as point (default is 6,6)
		 * @param strength		Glow strength
		 * @param innerGlow		Inner glow flag (default is false)
		 * @param knockout		Knockout flag (default is false)
		 */
		public function AddGlowFilterAction(object:*, color:uint, alpha:Number = 1, blur:Point = null, strength:Number = 1, innerGlow:Boolean = false, knockout:Boolean = false)
		{
			if(object is Display)
			{
				this.display = Display(object).displayObject;
			}
			else if(object is DisplayObject)
			{
				this.display = object;
			}
			else if (object is Entity)
			{
				this.display = object.get(Display).displayObject;
			}
			else if (object is String)
			{
				_charType = object;
			}
			
			this.color = color;
			this.alpha = alpha;
			this.strength = strength;
			this.inner = innerGlow;
			this.knockout = knockout;
			
			if(blur)
				this.blur = blur;
			else
				this.blur = new Point(6,6);
		}
		
		override public function preExecute(_pcallback:Function, group:Group, node:SpecialAbilityNode = null):void
		{
			var displayArray:Array = [];
			// if char type string
			if (_charType)
			{
				// get entity array
				var entityArray:Vector.<Entity> = CharacterGroup(group.getGroupById("characterGroup")).getNPCs(_charType);
				// convert to display objects
				for each (var npc:Entity in entityArray)
				{
					displayArray.push(npc.get(Display).displayObject);
				}
			}
			else if (display)
			{
				displayArray.push(display);
			}
			else
			{
				// else fail gracefully
				_pcallback();
				return;
			}

			for each (var char:DisplayObject in displayArray)
			{
				char.filters = [new GlowFilter(color, alpha, blur.x, blur.y, strength, PerformanceUtils.qualityLevel, inner, knockout)];
			}
		}
		
		override public function revert( group:Group ):void
		{
			// reset display to have no filters
			if (display)
				display.filters = [];
		}
	}
}