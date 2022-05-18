package game.systems.actionChain.actions
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Quad;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.systems.actionChain.ActionCommand;
	import game.util.TweenUtils;
	
	// Tween entity's component values
	// Use this instead of TweenAction whereever possible
	public class TweenNPCSAction extends ActionCommand
	{
		private var curTween:TweenMax;
		private var entity:Entity;
		private var component:Class;
		private var duration:Number;
		private var vars:Object;
		private var name:String;
		private var delay:Number;
		private var height:Number;
		private var includePlayer:Boolean;
		
		public function TweenNPCSAction( duration:Number, height:Number=0,includePlayer:Boolean=false ) 
		{
			this.component = Spatial;
			this.duration = duration;
			this.height = height;
			this.includePlayer = includePlayer;
		}
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			var entityArray:Vector.<Entity>;
			if(includePlayer == true)
				entityArray = CharacterGroup(group.getGroupById("characterGroup")).getCharactersInScene(false);
			else
				entityArray = CharacterGroup(group.getGroupById("characterGroup")).getNPCs("NPCS");
			
			for each(var char:Entity in entityArray)
			{
				var tweenheight:Number = char.get(Spatial).y - height;
				vars = new Object();
				vars = {y:tweenheight, ease:Quad.easeOut, yoyo:true, repeat:1 };
				curTween = TweenUtils.entityTo(char, component, duration, vars);
			}
			
		}
		
		override public function cancel():void 
		{
			if ( this.curTween ) 
			{
				this.curTween.kill();
			}
		}
	}
}

