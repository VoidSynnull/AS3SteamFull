package game.systems.actionChain.actions 
{
	import engine.group.Group;
	
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Calls a function with an argument list
	public class CallFunctionAction extends ActionCommand 
	{
		public var func:Function;
		public var args:Array = [];

		/**
		 * Calls a function with an argument list
		 * @param func		Function to call
		 * @param args		Argument list
		 */
		public function CallFunctionAction( func:Function, ... args ) 
		{
			this.func = func;
			if ((args) && (args.length != 0))
				this.args = args;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			this.func.apply(null,this.args);
/*			switch(args.length)
			{
				case 0:
					this.func();
					break;
				case 1:
					this.func(args[0]);
					break;
				case 2:
					this.func(args[0], args[1]);
					break;
				case 3:
					this.func(args[0], args[1], args[2]);
					break;
				case 4:
					this.func(args[0], args[1], args[2], args[3]);
					break;
				case 5:
					this.func(args[0], args[1], args[2], args[3], args[4]);
					break;
				case 6:
					this.func(args[0], args[1], args[2], args[3], args[4], args[5]);
					break;
				case 7:
					this.func(args[0], args[1], args[2], args[3], args[4], args[5], args[6]);
					break;
				case 8:
					this.func(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7]);
					break;
				case 9:
					this.func(args[0], args[1], args[2], args[3], args[4], args[5], args[6], args[7], args[8]);
					break;
				default:
					trace("CallFunctionAction can't handle " + args.length + " number of arguments!");
					break;
			}*/
			callback();	// once the waitStart timer has completed, execute() is called, and we finish right away.
		}
	}
}