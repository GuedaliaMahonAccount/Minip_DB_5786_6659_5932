CREATE TABLE public.department (
    department_id integer NOT NULL,
    dept_name character varying(255) NOT NULL,
    location character varying(255)
);

CREATE TABLE public.employee (
    employee_id integer NOT NULL,
    first_name character varying(50) NOT NULL,
    last_name character varying(50) NOT NULL,
    phone_number character varying(15),
    department_id integer,
    role_id integer,
    contract_id integer,
    birth_date date
);

CREATE TABLE public.employee_contract (
    contract_id integer NOT NULL,
    start_date date DEFAULT CURRENT_DATE NOT NULL,
    salary numeric(10,2) NOT NULL,
    CONSTRAINT chk_min_salary CHECK ((salary >= (5000)::numeric))
);

CREATE TABLE public.office (
    office_id integer NOT NULL,
    office_name character varying(255) NOT NULL,
    department_id integer,
    office_location character varying(255)
);

CREATE TABLE public.role (
    role_id integer NOT NULL,
    role_title character varying(255) NOT NULL
);

CREATE TABLE public.shift (
    shift_id integer NOT NULL,
    shift_type character varying(50) NOT NULL,
    start_time time without time zone NOT NULL
);

CREATE TABLE public.shift_assignment (
    assignment_id integer NOT NULL,
    employee_id integer,
    shift_id integer,
    work_date date NOT NULL
);

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_dept_name_key UNIQUE (dept_name);

ALTER TABLE ONLY public.department
    ADD CONSTRAINT department_pkey PRIMARY KEY (department_id);

ALTER TABLE ONLY public.employee_contract
    ADD CONSTRAINT employee_contract_pkey PRIMARY KEY (contract_id);

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_pkey PRIMARY KEY (employee_id);

ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_pkey PRIMARY KEY (office_id);

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (role_id);

ALTER TABLE ONLY public.shift_assignment
    ADD CONSTRAINT shift_assignment_pkey PRIMARY KEY (assignment_id);

ALTER TABLE ONLY public.shift
    ADD CONSTRAINT shift_pkey PRIMARY KEY (shift_id);

ALTER TABLE ONLY public.shift_assignment
    ADD CONSTRAINT unique_assignment UNIQUE (employee_id, shift_id, work_date);

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES public.employee_contract(contract_id);

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id);

ALTER TABLE ONLY public.employee
    ADD CONSTRAINT employee_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(role_id);

ALTER TABLE ONLY public.office
    ADD CONSTRAINT office_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.department(department_id);

ALTER TABLE ONLY public.shift_assignment
    ADD CONSTRAINT shift_assignment_employee_id_fkey FOREIGN KEY (employee_id) REFERENCES public.employee(employee_id);

ALTER TABLE ONLY public.shift_assignment
    ADD CONSTRAINT shift_assignment_shift_id_fkey FOREIGN KEY (shift_id) REFERENCES public.shift(shift_id);

