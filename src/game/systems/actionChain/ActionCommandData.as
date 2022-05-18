package game.systems.actionChain
{
	import game.data.ParamList;
	import game.util.ClassUtils;
	import game.util.DataUtils;

	public class ActionCommandData
	{
		public var className:Class;
		public var noWait:Boolean = false;
		public var lockOnAction:Boolean = false;
		public var startDelay:Number = 0;
		public var endDelay:Number = 0;
		
		public var params:ParamList;
		
		public function parseXML(actionXML:XML):Boolean
		{			
			var classString:String = DataUtils.getString(actionXML.attribute("class"));
			// if there is no path, auto assume game.systems.actionChain.actions.
			if(classString.indexOf(".") == -1)
			{
				classString = "game.systems.actionChain.actions." + classString;
			}
			try
			{
				var objectClass:Class = ClassUtils.getClassByName(classString);
			}
			catch (e:Error)
			{
				return false;
			}
			if (objectClass == null)
			{
				return false;
			}
			else
			{
				this.className = objectClass;
				
				this.noWait = DataUtils.getBoolean(actionXML.attribute("noWait"));
				this.lockOnAction = DataUtils.getBoolean(actionXML.attribute("lockInput"));
				this.startDelay = DataUtils.getNumber(actionXML.attribute("startDelay"));
				this.endDelay = DataUtils.getNumber(actionXML.attribute("endDelay"));
				
				if(isNaN(startDelay)) startDelay = 0;
				if(isNaN(endDelay)) endDelay = 0;			
				
				this.params = new ParamList(XML(actionXML.child("parameters")));
				return true;
			}
		}
	}
}