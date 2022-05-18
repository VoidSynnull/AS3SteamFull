package game.scene.template
{
	import flash.utils.Dictionary;
	
	import engine.group.Group;
	import engine.util.Command;
	
	import game.data.ParamDataTypes;
	import game.data.ParamList;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.ActionCommand;
	import game.systems.actionChain.ActionCommandData;
	import game.util.DataUtils;
	
	public class ActionsGroup extends Group
	{
		public function ActionsGroup(id:String = null)
		{
			super();
			this.id = GROUP_ID;
			if(id)
			{
				this.id += "_" + id;
			}
		}
		
		public function setupGroup(group:Group, data:XML = null):void
		{
			_group = group;
			addActionDatas(data)
			group.addChildGroup(this);	
		}
		
		public function revertAllChains():void
		{
			for each(var actionChain:ActionChain in _actionChainsMade)
			{
				actionChain.revokeActions();
			}
		}
		
		/**
		 * 
		 * @param id - the string id of the action chain (specified in XML)
		 * @param paramDict - dictionary of param values like an entity or something in code (specified in XML with '[' & ']')
		 * @return 
		 * 
		 */
		public function getActionChain(id:String, paramDict:Dictionary = null):ActionChain
		{
			for(var key:String in actionChains)
			{
				trace("action: " + key + " key " + id);
				// Check the id against the xml id
				if(key == id)
				{
					// create the new chain now and pass it back to the coder
					var newChain:ActionChain = new ActionChain(_group);	
					for each(var data:ActionCommandData in actionChains[key])
					{
						var params:ParamList = ParamDataTypes.convertParams(data.params, _group, paramDict);
						var action:ActionCommand;
						if(params.getParamByIndex(0).type == ParamDataTypes.FUNCTION)
						{
							if(_group.hasOwnProperty(params.getParamByIndex(0).value))
							{
								var func:Function = _group[params.getParamByIndex(0).value];
								params.removeParamByIndex(0);
								func = createCommand(func, params);
								action = new data.className(func);
							}
						}
						else
						{
							action = create(data.className, params);
						}
						
						action.lockInput = data.lockOnAction;
						action.startDelay = data.startDelay;
						action.endDelay = data.endDelay;
						action.noWait = data.noWait;
						newChain.addAction(action);
					}
					
					if(!_actionChainsMade) _actionChainsMade = new Array();
					_actionChainsMade.push(newChain);
					
					return newChain;
				}
			}
			
			return null;
		}
		
		public function addActionDatas(actionsXML:XML, idExtension:String = null):void
		{
			if(actionsXML != null)
			{
				if(actionsXML.hasOwnProperty("@id"))
				{
					this.id += "_"+actionsXML.attribute("id")[0];
				}
				actionChains = new Dictionary();
				for each(var actionChain:XML in actionsXML.actionChain)
				{
					var actionsArray:Array = new Array();
					for each(var action:XML in actionChain.action)
					{
						var data:ActionCommandData = new ActionCommandData();
						// if parsing doesn't fail, then add to array
						// parsing will fail if the class is not found
						if (data.parseXML(action))
						{
							actionsArray.push(data);
						}
					}					
					
					var id:String = DataUtils.getString(actionChain.attribute("id"));
					if(idExtension)
						id += "_" + idExtension;
					
					actionChains[id] = actionsArray;
				}
			}
		}
		
		private function create(what:Class, args:ParamList):*
		{
			if(!args) return null;
			
			switch(args.length)
			{
				case 0: return new what();
				case 1: return new what(args.byIndex(0));
				case 2: return new what(args.byIndex(0), args.byIndex(1));
				case 3: return new what(args.byIndex(0), args.byIndex(1), args.byIndex(2));
				case 4: return new what(args.byIndex(0), args.byIndex(1), args.byIndex(2), args.byIndex(3));
				case 5: return new what(args.byIndex(0), args.byIndex(1), args.byIndex(2), args.byIndex(3), args.byIndex(4));
				case 6: return new what(args.byIndex(0), args.byIndex(1), args.byIndex(2), args.byIndex(3), args.byIndex(4), args.byIndex(5));
				case 7: return new what(args.byIndex(0), args.byIndex(1), args.byIndex(2), args.byIndex(3), args.byIndex(4), args.byIndex(5), args.byIndex(6));
				case 8: return new what(args.byIndex(0), args.byIndex(1), args.byIndex(2), args.byIndex(3), args.byIndex(4), args.byIndex(5), args.byIndex(6), args.byIndex(7));
				case 9: return new what(args.byIndex(0), args.byIndex(1), args.byIndex(2), args.byIndex(3), args.byIndex(4), args.byIndex(5), args.byIndex(6), args.byIndex(7), args.byIndex(8));
				case 10: return new what(args.byIndex(0), args.byIndex(1), args.byIndex(2), args.byIndex(3), args.byIndex(4), args.byIndex(5), args.byIndex(6), args.byIndex(7), args.byIndex(8), args.byIndex(9));
				default:
					throw new Error("Actions Group :: Properties cannot exceed a limit of 10.");
					break;
			}
		}
		
		private function createCommand(func:Function, params:ParamList):Function
		{
			if(!params) return null;
			
			switch(params.length)
			{
				case 0: return Command.create(func);
				case 1: return Command.create(func, params.byIndex(0));
				case 2: return Command.create(func, params.byIndex(0), params.byIndex(1));
				case 3: return Command.create(func, params.byIndex(0), params.byIndex(1), params.byIndex(2));
				case 4: return Command.create(func, params.byIndex(0), params.byIndex(1), params.byIndex(2), params.byIndex(3));
				case 5: return Command.create(func, params.byIndex(0), params.byIndex(1), params.byIndex(2), params.byIndex(3), params.byIndex(4));
				case 6: return Command.create(func, params.byIndex(0), params.byIndex(1), params.byIndex(2), params.byIndex(3), params.byIndex(4), params.byIndex(5));	
				case 7: return Command.create(func, params.byIndex(0), params.byIndex(1), params.byIndex(2), params.byIndex(3), params.byIndex(4), params.byIndex(5), params.byIndex(6));
				case 8: return Command.create(func, params.byIndex(0), params.byIndex(1), params.byIndex(2), params.byIndex(3), params.byIndex(4), params.byIndex(5), params.byIndex(6), params.byIndex(7));
				case 9: return Command.create(func, params.byIndex(0), params.byIndex(1), params.byIndex(2), params.byIndex(3), params.byIndex(4), params.byIndex(5), params.byIndex(6), params.byIndex(7), params.byIndex(8));
				case 10: return Command.create(func, params.byIndex(0), params.byIndex(1), params.byIndex(2), params.byIndex(3), params.byIndex(4), params.byIndex(5), params.byIndex(6), params.byIndex(7), params.byIndex(8), params.byIndex(9));
				default:
					throw new Error("Actions Group :: Properties cannot exceed a limit of 10.");
					break;
			}
			
			return null;
		}
		
		public static const GROUP_ID:String = "actionsGroup";
		private var _group:Group;
		public var actionChains:Dictionary;
		
		private var _actionChainsMade:Array;
	}
}