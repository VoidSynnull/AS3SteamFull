package game.proxy.browser
{
	import flash.net.ObjectEncoding;
	import flash.net.SharedObject;
	import flash.utils.Dictionary;
	
	import engine.Manager;
	
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.proxy.ILegacyDataManager;
	import game.util.DataUtils;
	import game.util.SkinUtils;
	
	/**
	 * BROWSER ONLY
	 * This class manages maintainance of the AS2 LSO
	 * @author umckiba
	 * 
	 */
	public class LegacyDataManager extends Manager implements ILegacyDataManager
	{
		private var _sharedObject:SharedObject;
		
		public function LegacyDataManager()
		{
			super();
		}
		
		public function get as2lso():SharedObject
		{
			if( _sharedObject == null )
			{
				_sharedObject = SharedObject.getLocal("Char", "/");
				_sharedObject.objectEncoding = ObjectEncoding.AMF0;
			}
			return _sharedObject;
		}
		
		//////////// PLAYER ////////////
		
		public function savePlayerLook( lookData:LookData, callback:Function=null):void
		{
			// Keep the as2 lso in sync when saving look.
			if( lookData == null )
			{
				lookData = SkinUtils.getLook(shellApi.player, true);
			}
			
			if( lookData != null )
			{
				var lso:SharedObject = this.as2lso;
				if (lso) {
					new LookConverter().applyLookDataToAS2LSO(lookData, shellApi.player, lso);
					lso.flush();
				}
			}
		}
		
		//////////// USERFIELDS ////////////
		
		/**
		 * Retrieve a value from user field from AS2LSO
		 */
		public function getUserField( fieldId:String ):*
		{
			trace( this,":: getUserField : looking for field: " + fieldId );
			
			var value:*;			
			var lso:SharedObject = this.as2lso;
			if ( lso.data.userData )				
			{
				
				value = lso.data.userData[fieldId];
				
				if ( !DataUtils.isNull(value) )	
				{
					trace( this,":: getUserField : filed: " + fieldId + " found in lso : " + value );
					return value;
				} 
				else
				{
					trace( this,":: getUserField : fieldValue found in lso was invalid." );
				}
			} 
			
			return null;
		}
		
		/**
		 * Retrieve a value from user field form external storage (LSO, server)
		 * Checks AS2lso first, if not found there checks & fromServer is true, retrieves from server.
		 * On result the filed value is set locally and returned with the callback.
		 */
		public function getUserFields( fieldIds:Array ):Dictionary
		{
			trace( this,":: getUserFields : looking for fields: " + fieldIds );
			var value:*;
			var fieldId:String;
			var fieldValues:Dictionary = new Dictionary();
			
			// check as2LSO for field
			var notInAS2LSO:Boolean = false;
			var lso:SharedObject = this.as2lso;
			if ( lso.data.userData )				
			{
				var i:int = 0;
				for (i; i < fieldIds.length; i++) 
				{
					fieldId = fieldIds[i];
					value = lso.data.userData[fieldId];
					if( DataUtils.isNull( value ) )
					{
						trace( this,":: value for userfield : " + fieldId + " was null" );
						notInAS2LSO = true;
					}
					else
					{
						fieldValues[fieldId] = value;
					}
				}
				
				if ( !notInAS2LSO )	
				{
					trace( this,":: getUserField : all fields found in AS2LSO" );
					return fieldValues;
				} 
			} 
			
			return null;
		}
		
		/**
		 * Set user field on AS2 LSO
		 * @param fieldId
		 * @param fieldValue
		 * @param islandName
		 */
		public function setUserField( fieldId:String, fieldValue:* ):void
		{
			trace( this,":: setUserField : fieldId: " + fieldId + " value: " + fieldValue );
			var lso:SharedObject = this.as2lso;
			var data:Object = lso.data.userData;
			if ( !data ) 
			{
				data = lso.data.userData = new Object();
			}

			data[ fieldId ] = fieldValue;
			lso.flush();
		}
		
		//////////// USERFIELDS ACCOUNTING FOR ISLAND ////////////
		// NOT IN USE //
		/*
			The AS2LSO reflects the same userfield storage structure as the server, 
			which is to keep the userfields flat, therefore island specification is not necessary.
		
			Keeping this code around just incase we ever decide to chnage how we store things and start using island
		*/
		/**
		 * Retrieve a value from user field from AS2LSO
		 */
		/*
		public function getUserField( fieldId:String, islandName:String = ""):*
		{
			trace( this,":: getUserField : looking for field: " + fieldId + " in island: " + islandName );
			
			var value:*;			
			var lso:SharedObject = this.as2lso;
			if ( lso.data.userData )				
			{
				if ( DataUtils.validString(islandName) ) 
				{
					if( lso.data.userData[islandName] )
					{
						value = lso.data.userData[islandName][fieldId];
					}
					else
					{
						trace( this,":: getUserField : checked LSO no user data for island : " + islandName );
					}
				} 
				else 
				{
					value = lso.data.userData[fieldId];
				}
				
				if ( !DataUtils.isNull(value) )	
				{
					trace( this,":: getUserField : filed: " + fieldId + " found in lso : " + value );
					return value;
				} 
				else
				{
					trace( this,":: getUserField : fieldValue found in lso was invalid." );
				}
			} 
			
			return null;
		}
		*/
		
		/**
		 * Retrieve a value from user field form external storage (LSO, server)
		 * Checks AS2lso first, if not found there checks & fromServer is true, retrieves from server.
		 * On result the filed value is set locally and returned with the callback.
		 */
		/*
		public function getUserFields( fieldIds:Array, islandName:String = "" ):Dictionary
		{
			trace( this,":: getUserField : looking for fields: " + fieldIds + " in island: " + islandName );
			var value:*;
			var fieldId:String;
			var fieldValues:Dictionary = new Dictionary();
			
			// check as2LSO for field
			var notInAS2LSO:Boolean = false;
			var lso:SharedObject = this.as2lso;
			if ( lso.data.userData )				
			{
				var i:int;
				if ( DataUtils.validString(islandName) ) 
				{
					if( lso.data.userData[islandName] )
					{
						for (i = 0; i < fieldIds.length; i++) 
						{
							fieldId = fieldIds[i];
							value = lso.data.userData[islandName][fieldId];
							if( DataUtils.isNull( value ) )
							{
								trace( this,":: value for userfield : " + fieldId + " was null" );
								notInAS2LSO = true;
							}
							else
							{
								fieldValues[fieldId] = value;
							}
						}
					}
					else
					{
						trace( this,":: getUserField : checked LSO no user data for island : " + islandName );
						notInAS2LSO = true;
					}
				} 
				else 
				{
					for (i = 0; i < fieldIds.length; i++) 
					{
						fieldId = fieldIds[i];
						value = lso.data.userData[fieldId];
						if( DataUtils.isNull( value ) )
						{
							trace( this,":: value for userfield : " + fieldId + " was null" );
							notInAS2LSO = true;
						}
						else
						{
							fieldValues[fieldId] = value;
						}
					}
				}
				
				if ( !notInAS2LSO )	
				{
					trace( this,":: getUserField : all fields found in AS2LSO" );
					return fieldValues;
				} 
			} 
			
			return null;
		}
		*/
		
		/**
		 * Set user field on AS2 LSO
		 * @param fieldId
		 * @param fieldValue
		 * @param islandName
		 * 
		 */
		/*
		public function setUserField( fieldId:String, fieldValue:*, islandName:String ):void
		{
			var lso:SharedObject = this.as2lso;
			var data:Object = lso.data.userData;
			if ( !data ) 
			{
				data = lso.data.userData = new Object();
			}
			
			if ( DataUtils.validString(islandName) )
			{
				if (data[islandName] == null) 
				{
					data[islandName] = new Dictionary();
				}
				data[islandName][fieldId] = fieldValue;
			} 
			else 
			{
				data[ fieldId ] = fieldValue;
			}
			lso.flush();
		}
		*/
	}
}