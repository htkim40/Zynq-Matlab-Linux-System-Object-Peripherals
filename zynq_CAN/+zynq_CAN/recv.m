classdef recv < zynq_CAN.base
    %recv CAN Receive socket
    %   Receive messages from the network
    
    properties (Nontunable)        
        % FilterIDs 
        %
        % The message IDs to filter for
        % A vector of 11-bit message IDs
        FilterIDs = 0;
        
        % FilterMasks
        %
        % The mask for the filter IDs
        % A vector of 11-bit message ID masks
        FilterMasks = 0;
        
        % Timeout
        %
        % The timeout for receiving data
        %
        % 0 = non-blocking
        % Inf = Blocking
        % Other values = timeout in seconds
        Timeout = Inf;
    end
    
    properties (Nontunable, Logical)
        % FilterEnable
        %
        % Enable the message ID filters
        % If true, enables filtering of received messages
        FilterEnable = false
    end
    
    properties (Hidden, Access = protected, Dependent)
        privTimeout;
    end
    
    
    properties (Hidden, Access = protected)
    end
    
    methods
        function val = get.privTimeout(obj)
            if obj.Timeout == Inf
                val = -1.0;
            else
                val = double(obj.Timeout);
            end
        end
    end
    
    methods (Access = protected)
        function setupImpl(obj)
            if obj.FilterEnable
                nFilt = numel(obj.FilterIDs);
                %opens the socket with filter here. Filter mask occurs in C
                %code
                openSocket(obj, nFilt, obj.FilterIDs, obj.FilterMasks);
            else
                openSocket(obj, 0);
            end
        end
        
        function [status, id, data, ts] = stepImpl(obj)
            %initializing variables            
            status = coder.nullcopy(int32(0));
            data_tmp = coder.nullcopy(zeros(1,64, 'uint8'));
            len =uint8(0);
            ts = double(-1.0);
            id = uint32(0);
            data=uint8([]);
            if coder.target('Rtw')
                status = coder.ceval('recvCANData', obj.socket,...
                    obj.privTimeout, coder.wref(id), coder.wref(len),...
                    coder.wref(data_tmp));
                if status
                    id(:) = 0;
                    ts(:) = -1;
                    data=uint8([]);
                else
                    coder.ceval('getRecvTimestamp', obj.socket,...
                        coder.wref(ts));
                    if(len > 0)
                        data = data_tmp(1:len);
                    end
                end
            end
        end
        
        function icon = getIconImpl(obj) %#ok<MANU>
            icon = sprintf('CAN Receive');
        end
        
        function flag = isInactivePropertyImpl(obj, prop)
            flag = false;
            switch (prop)
                case {'FilterIDs', 'FilterMasks'}
                    flag = ~obj.FilterEnable;
            end
        end
    end
    
    %% External Dependency Methods
    methods (Static)
        function bName = getDescriptiveName(~)
            % getDescriptiveName get the name of the block
            % Internal function for Simulink Block generation
            bName = 'CAN Receive';
        end
    end
    
    methods (Hidden, Static, Access = protected)
        function groups = getPropertyGroupsImpl
            groups = matlab.system.display.Section(...
                'PropertyList',{'CANDev','Timeout','FilterEnable',...
                'FilterIDs', 'FilterMasks'});
        end
    end
    
    %% Propagation Methods
    methods (Hidden, Access = protected)
        
         %% Inputs validation
        
        function validatePropertiesImpl(~)
        end
        
        %% Initializers / Value Getters
        function N = getNumOutputsImpl(~)
            % Specify number of System Outputs
            N = 4;
        end
        
        function [status, id, data, ts] = getOutputSizeImpl(~)
            status = 1;
            id = 1;
            data = 64;
            ts = 1;
        end
        
        function [status, id, data, ts]= isOutputFixedSizeImpl(~)
            status = true;
            id = true;
            data = false;
            ts = true;
        end
        
        function [status, id, data, ts] = getOutputDataTypeImpl(~)
            status = 'int32';
            id = 'uint32';
            data = 'uint8';
            ts = 'double';
        end
        
        function [status, id, data, ts] =  getOutputNamesImpl(~)
            status = 'Status';
            id = 'ID';
            data = 'Data';
            ts = 'Timestamp';
        end
        
        function [status, id, data, ts] = isOutputComplexImpl(~)
            status = false;
            id = false;
            data = false;
            ts = false;
        end
    end
end

